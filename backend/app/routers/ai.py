"""AI routes: tagging, missing pieces."""
import json
from typing import Optional

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_db, get_current_user
from app.models.user import User
from app.models.wardrobe import WardrobeItem
from app.schemas.ai import (
    AITagRequest,
    MissingPieceRequest,
    MissingPieceResponse,
    MissingPieceItem,
    AITagResponse,
)
from app.services import ai_service

router = APIRouter(prefix="/ai", tags=["ai"])


@router.post("/tag", response_model=AITagResponse)
async def tag_garment_endpoint(
    description: str = "",
    user: User = Depends(get_current_user),
):
    """Tag a garment from a text description (no image upload)."""
    try:
        tags = await ai_service.tag_garment_from_description(description or "a clothing item")
        return AITagResponse(**tags)
    except Exception:
        # Graceful fallback — don't crash on LLM failure
        return AITagResponse(
            name="Unknown Item",
            category="other",
            description="AI tagging temporarily unavailable. Please fill in details manually.",
        )


@router.post("/missing-pieces", response_model=MissingPieceResponse)
async def missing_pieces(
    payload: MissingPieceRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Analyze wardrobe for missing pieces for an event."""
    result = await db.execute(select(WardrobeItem).where(WardrobeItem.user_id == user.id))
    items = list(result.scalars().all())
    item_dicts = [
        {
            "id": i.id,
            "name": i.name,
            "category": i.category,
            "color_primary": i.color_primary,
            "formality_level": i.formality_level,
        }
        for i in items
    ]

    try:
        ai_result = await ai_service.find_missing_pieces(
            item_dicts, payload.event_type, payload.dress_code, payload.budget_max
        )
    except Exception:
        return MissingPieceResponse(
            event_type=payload.event_type,
            have=[i["category"] for i in item_dicts],
            missing=[],
            summary="AI analysis temporarily unavailable. Please try again.",
        )

    missing = [MissingPieceItem(**m) for m in ai_result.get("missing", [])]
    return MissingPieceResponse(
        event_type=ai_result.get("event_type", payload.event_type),
        have=ai_result.get("have", []),
        missing=missing,
        summary=ai_result.get("summary"),
    )
