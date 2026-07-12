"""Outfit routes: recommendations + history + feedback."""
import uuid
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_db, get_current_user
from app.models.user import User, UserProfile
from app.models.wardrobe import WardrobeItem
from app.models.outfit import Outfit, OutfitItem, OutfitFeedback
from app.schemas.outfit import OutfitRecommendationRequest, OutfitResponse, OutfitItemSlot, OutfitFeedbackRequest
from app.schemas.wardrobe import WardrobeItemResponse
from app.services import ai_service, weather_service

router = APIRouter(prefix="/outfits", tags=["outfits"])


def _item_to_dict(item: WardrobeItem) -> dict:
    return {
        "id": item.id,
        "name": item.name,
        "category": item.category,
        "color_primary": item.color_primary,
        "color_secondary": item.color_secondary,
        "pattern": item.pattern,
        "formality_level": item.formality_level,
        "season": item.season,
        "brand": item.brand,
    }


@router.post("/recommend", response_model=OutfitResponse)
async def recommend_outfit(
    payload: OutfitRecommendationRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Load wardrobe
    result = await db.execute(
        select(WardrobeItem).where(WardrobeItem.user_id == user.id)
    )
    items = list(result.scalars().all())

    if not items:
        return OutfitResponse(
            name="No Items Yet",
            occasion=payload.occasion,
            items=[],
            ai_reasoning="Add items to your wardrobe and I'll recommend outfits for you!",
            ai_confidence_score=0,
        )

    # Load profile
    profile_result = await db.execute(select(UserProfile).where(UserProfile.user_id == user.id))
    profile = profile_result.scalar_one_or_none()
    profile_data = None
    if profile:
        profile_data = {
            "preferred_colors": profile.preferred_colors or [],
            "style_preferences": profile.style_preferences or [],
            "favorite_occasions": profile.favorite_occasions or [],
        }

    # Weather context
    weather_data = None
    if payload.weather_temp_c is not None:
        weather_data = {
            "temp_c": payload.weather_temp_c,
            "condition": payload.weather_condition,
        }
    elif payload.city:
        snap = await weather_service.get_weather(db, payload.city)
        if snap:
            weather_data = {
                "temp_c": float(snap.temperature_c),
                "condition": snap.condition_text,
            }

    # AI recommendation
    item_dicts = [_item_to_dict(i) for i in items]
    try:
        ai_result = await ai_service.recommend_outfit(
            item_dicts, payload.occasion or "casual", weather_data, profile_data
        )
    except Exception:
        return OutfitResponse(
            name="Smart Casual Pick",
            occasion=payload.occasion,
            items=[],
            ai_reasoning="I'm having trouble with the styling engine. Please try again.",
            ai_confidence_score=0,
        )

    # Map AI item_ids to actual items
    item_map = {i.id: i for i in items}
    outfit_items: list[OutfitItemSlot] = []
    for ai_item in ai_result.get("items", []):
        item_id = ai_item.get("item_id")
        if item_id and item_id in item_map:
            outfit_items.append(
                OutfitItemSlot(
                    role=ai_item.get("role", "top"),
                    item=WardrobeItemResponse.model_validate(item_map[item_id]),
                )
            )

    # Save outfit
    outfit = Outfit(
        user_id=user.id,
        name=ai_result.get("name", "AI Outfit"),
        occasion=payload.occasion,
        weather_context=weather_data.get("condition") if weather_data else None,
        ai_confidence_score=ai_result.get("confidence_score", 0.5),
        is_ai_generated=True,
    )
    db.add(outfit)
    await db.flush()
    for slot in outfit_items:
        db.add(OutfitItem(
            outfit_id=outfit.id,
            wardrobe_item_id=slot.item.id,
            role=slot.role,
        ))

    return OutfitResponse(
        id=outfit.id,
        name=outfit.name,
        occasion=outfit.occasion,
        weather_context=outfit.weather_context,
        ai_confidence_score=outfit.ai_confidence_score,
        is_ai_generated=True,
        items=outfit_items,
        ai_reasoning=ai_result.get("ai_reasoning"),
    )


@router.get("/history", response_model=list[OutfitResponse])
async def outfit_history(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Outfit)
        .where(Outfit.user_id == user.id)
        .order_by(Outfit.created_at.desc())
        .limit(20)
    )
    outfits = list(result.scalars().all())
    responses = []
    for o in outfits:
        items_result = await db.execute(
            select(OutfitItem).where(OutfitItem.outfit_id == o.id)
        )
        slots = []
        for oi in items_result.scalars().all():
            item_result = await db.execute(
                select(WardrobeItem).where(WardrobeItem.id == oi.wardrobe_item_id)
            )
            item = item_result.scalar_one_or_none()
            if item:
                slots.append(OutfitItemSlot(role=oi.role, item=WardrobeItemResponse.model_validate(item)))
        responses.append(OutfitResponse(
            id=o.id,
            name=o.name,
            occasion=o.occasion,
            weather_context=o.weather_context,
            ai_confidence_score=o.ai_confidence_score,
            is_ai_generated=o.is_ai_generated,
            items=slots,
            created_at=o.created_at,
        ))
    return responses


@router.post("/{outfit_id}/feedback", status_code=201)
async def submit_feedback(
    outfit_id: int,
    payload: OutfitFeedbackRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Outfit).where(Outfit.id == outfit_id, Outfit.user_id == user.id))
    outfit = result.scalar_one_or_none()
    if not outfit:
        raise HTTPException(404, "Outfit not found")
    fb = OutfitFeedback(outfit_id=outfit_id, user_id=user.id, feedback=payload.feedback)
    db.add(fb)
    await db.flush()
    return {"status": "ok", "feedback": payload.feedback}


@router.post("/recommend/alternative", response_model=OutfitResponse)
async def recommend_alternative(
    payload: OutfitRecommendationRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Generate a different outfit recommendation (used when user rejects the first)."""
    # Simply call recommend again — the AI engine generates varied results
    # but we exclude items from the most recent rejected outfit
    last_result = await db.execute(
        select(Outfit)
        .where(Outfit.user_id == user.id)
        .order_by(Outfit.created_at.desc())
        .limit(1)
    )
    last_outfit = last_result.scalar_one_or_none()

    excluded_ids = set()
    if last_outfit:
        items_result = await db.execute(
            select(OutfitItem).where(OutfitItem.outfit_id == last_outfit.id)
        )
        excluded_ids = {oi.wardrobe_item_id for oi in items_result.scalars().all()}

    # Load wardrobe excluding the rejected outfit's items (if possible)
    result = await db.execute(
        select(WardrobeItem).where(WardrobeItem.user_id == user.id)
    )
    all_items = list(result.scalars().all())
    items = [i for i in all_items if i.id not in excluded_ids] if len(all_items) > len(excluded_ids) else all_items

    if not items:
        return OutfitResponse(
            name="No Items Yet",
            occasion=payload.occasion,
            items=[],
            ai_reasoning="Add items to your wardrobe and I'll recommend outfits for you!",
            ai_confidence_score=0,
        )

    profile_result = await db.execute(select(UserProfile).where(UserProfile.user_id == user.id))
    profile = profile_result.scalar_one_or_none()
    profile_data = None
    if profile:
        profile_data = {
            "preferred_colors": profile.preferred_colors or [],
            "style_preferences": profile.style_preferences or [],
            "favorite_occasions": profile.favorite_occasions or [],
        }

    weather_data = None
    if payload.weather_temp_c is not None:
        weather_data = {"temp_c": payload.weather_temp_c, "condition": payload.weather_condition}
    elif payload.city:
        snap = await weather_service.get_weather(db, payload.city)
        if snap:
            weather_data = {"temp_c": float(snap.temperature_c), "condition": snap.condition_text}

    item_dicts = [_item_to_dict(i) for i in items]
    try:
        ai_result = await ai_service.recommend_outfit(
            item_dicts, payload.occasion or "casual", weather_data, profile_data
        )
    except Exception:
        return OutfitResponse(
            name="Alternative Pick",
            occasion=payload.occasion,
            items=[],
            ai_reasoning="I'm having trouble with the styling engine. Please try again.",
            ai_confidence_score=0,
        )

    item_map = {i.id: i for i in items}
    outfit_items: list[OutfitItemSlot] = []
    for ai_item in ai_result.get("items", []):
        item_id = ai_item.get("item_id")
        if item_id and item_id in item_map:
            outfit_items.append(
                OutfitItemSlot(
                    role=ai_item.get("role", "top"),
                    item=WardrobeItemResponse.model_validate(item_map[item_id]),
                )
            )

    outfit = Outfit(
        user_id=user.id,
        name=ai_result.get("name", "AI Alternative Outfit"),
        occasion=payload.occasion,
        weather_context=weather_data.get("condition") if weather_data else None,
        ai_confidence_score=ai_result.get("confidence_score", 0.5),
        is_ai_generated=True,
    )
    db.add(outfit)
    await db.flush()
    for slot in outfit_items:
        db.add(OutfitItem(
            outfit_id=outfit.id,
            wardrobe_item_id=slot.item.id,
            role=slot.role,
        ))

    return OutfitResponse(
        id=outfit.id,
        name=outfit.name,
        occasion=outfit.occasion,
        weather_context=outfit.weather_context,
        ai_confidence_score=outfit.ai_confidence_score,
        is_ai_generated=True,
        items=outfit_items,
        ai_reasoning=ai_result.get("ai_reasoning"),
    )
