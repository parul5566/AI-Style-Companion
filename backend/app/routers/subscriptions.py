"""Subscription routes."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_db, get_current_user
from app.models.user import User
from app.models.subscription import Subscription, TIER_CONFIG
from app.schemas.subscription import SubscriptionResponse, TierUpdateRequest, TierInfo

router = APIRouter(prefix="/subscriptions", tags=["subscriptions"])


async def _get_or_create_sub(db: AsyncSession, user_id: int) -> Subscription:
    result = await db.execute(select(Subscription).where(Subscription.user_id == user_id))
    sub = result.scalar_one_or_none()
    if not sub:
        sub = Subscription(user_id=user_id, tier="free")
        db.add(sub)
        await db.flush()
    return sub


@router.get("", response_model=SubscriptionResponse)
async def get_subscription(user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    return await _get_or_create_sub(db, user.id)


@router.get("/tiers", response_model=list[TierInfo])
async def get_tiers():
    prices = {"free": "Free", "basic": "$9.99/mo", "plus": "$19.99/mo", "premium": "$39.99/mo"}
    return [
        TierInfo(
            name=name,
            credits_monthly=cfg["credits_monthly"],
            features=cfg["features"],
            price_label=prices.get(name, ""),
        )
        for name, cfg in TIER_CONFIG.items()
    ]


@router.put("/tier", response_model=SubscriptionResponse)
async def update_tier(
    payload: TierUpdateRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    sub = await _get_or_create_sub(db, user.id)
    sub.tier = payload.tier
    sub.tryon_credits_monthly = TIER_CONFIG[payload.tier]["credits_monthly"]
    sub.tryon_credits_remaining = TIER_CONFIG[payload.tier]["credits_monthly"]
    await db.flush()
    return sub
