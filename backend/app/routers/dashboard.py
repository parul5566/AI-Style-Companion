"""Dashboard routes: aggregated summary."""
from datetime import datetime, timedelta
from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_db, get_current_user
from app.models.user import User, UserProfile
from app.models.wardrobe import WardrobeItem
from app.models.outfit import Outfit, OutfitItem
from app.models.event import Event
from app.models.subscription import Subscription
from app.schemas.dashboard import DashboardSummary, WeatherInfo, WardrobeStats
from app.schemas.outfit import OutfitResponse, OutfitItemSlot
from app.schemas.wardrobe import WardrobeItemResponse
from app.schemas.ai import MissingPieceItem
from app.services import weather_service, ai_service

router = APIRouter(prefix="/dashboard", tags=["dashboard"])


@router.get("/summary", response_model=DashboardSummary)
async def dashboard_summary(
    city: str = Query(default="London"),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Wardrobe stats
    total_result = await db.execute(
        select(func.count(WardrobeItem.id)).where(WardrobeItem.user_id == user.id)
    )
    total_items = total_result.scalar() or 0

    cat_result = await db.execute(
        select(WardrobeItem.category, func.count(WardrobeItem.id))
        .where(WardrobeItem.user_id == user.id)
        .group_by(WardrobeItem.category)
    )
    by_category = {row[0]: row[1] for row in cat_result.all()}

    fav_result = await db.execute(
        select(func.count(WardrobeItem.id)).where(
            WardrobeItem.user_id == user.id, WardrobeItem.is_favorite == True
        )
    )
    favorites_count = fav_result.scalar() or 0

    week_ago = datetime.utcnow() - timedelta(days=7)
    worn_result = await db.execute(
        select(func.count(WardrobeItem.id)).where(
            WardrobeItem.user_id == user.id, WardrobeItem.last_worn_date >= week_ago.date()
        )
    )
    recently_worn_count = worn_result.scalar() or 0

    # Weather
    weather = None
    weather_data = None
    try:
        snap = await weather_service.get_weather(db, city)
        if snap:
            weather = WeatherInfo(
                city=snap.city,
                temperature_c=float(snap.temperature_c),
                feels_like_c=float(snap.feels_like_c) if snap.feels_like_c else None,
                condition_text=snap.condition_text,
                humidity=snap.humidity,
                wind_kph=float(snap.wind_kph) if snap.wind_kph else None,
            )
            weather_data = {"temp_c": float(snap.temperature_c), "condition": snap.condition_text}
    except Exception:
        pass

    # Upcoming events
    events_result = await db.execute(
        select(Event)
        .where(Event.user_id == user.id, Event.event_date >= datetime.utcnow())
        .order_by(Event.event_date.asc())
        .limit(5)
    )
    upcoming_events = [
        {"id": e.id, "title": e.title, "event_type": e.event_type, "event_date": e.event_date.isoformat()}
        for e in events_result.scalars().all()
    ]

    # Subscription
    sub_result = await db.execute(select(Subscription).where(Subscription.user_id == user.id))
    sub = sub_result.scalar_one_or_none()
    tier = sub.tier if sub else "free"
    credits = sub.tryon_credits_remaining if sub else 0

    # Today's outfit — get the most recent outfit from history with its items
    today_outfit = None
    outfit_result = await db.execute(
        select(Outfit)
        .where(Outfit.user_id == user.id)
        .order_by(Outfit.created_at.desc())
        .limit(1)
    )
    last_outfit = outfit_result.scalar_one_or_none()
    if last_outfit:
        items_result = await db.execute(
            select(OutfitItem).where(OutfitItem.outfit_id == last_outfit.id)
        )
        slots = []
        for oi in items_result.scalars().all():
            item_result = await db.execute(
                select(WardrobeItem).where(WardrobeItem.id == oi.wardrobe_item_id)
            )
            item = item_result.scalar_one_or_none()
            if item:
                slots.append(OutfitItemSlot(role=oi.role, item=WardrobeItemResponse.model_validate(item)))
        today_outfit = OutfitResponse(
            id=last_outfit.id,
            name=last_outfit.name,
            occasion=last_outfit.occasion,
            weather_context=last_outfit.weather_context,
            ai_confidence_score=last_outfit.ai_confidence_score,
            is_ai_generated=last_outfit.is_ai_generated,
            items=slots,
            created_at=last_outfit.created_at,
        )

    # Missing pieces (lightweight - only run if user has items)
    missing_items = []
    if total_items > 0:
        try:
            items_result = await db.execute(
                select(WardrobeItem).where(WardrobeItem.user_id == user.id).limit(50)
            )
            item_dicts = [
                {"id": i.id, "name": i.name, "category": i.category}
                for i in items_result.scalars().all()
            ]
            mp = await ai_service.find_missing_pieces(item_dicts, "everyday casual")
            missing_items = [MissingPieceItem(**m) for m in mp.get("missing", [])][:3]
        except Exception:
            pass

    return DashboardSummary(
        weather=weather,
        today_outfit=today_outfit,
        wardrobe_stats=WardrobeStats(
            total_items=total_items,
            by_category=by_category,
            favorites_count=favorites_count,
            recently_worn_count=recently_worn_count,
        ),
        missing_items=missing_items,
        upcoming_events=upcoming_events,
        subscription_tier=tier,
        tryon_credits=credits,
    )
