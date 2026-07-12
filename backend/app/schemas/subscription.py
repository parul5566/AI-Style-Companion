"""Subscription schemas."""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class SubscriptionResponse(BaseModel):
    id: int
    user_id: int
    tier: str
    tryon_credits_remaining: int
    tryon_credits_monthly: int
    is_active: bool
    started_at: datetime
    renews_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


class TierUpdateRequest(BaseModel):
    tier: str = Field(pattern="^(free|basic|plus|premium)$")


class TierInfo(BaseModel):
    name: str
    credits_monthly: int
    features: list[str]
    price_label: str
