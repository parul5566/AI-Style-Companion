"""Profile schemas."""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class ProfileUpdate(BaseModel):
    gender: Optional[str] = None
    age_range: Optional[str] = None
    budget_min: Optional[int] = None
    budget_max: Optional[int] = None
    preferred_colors: Optional[list[str]] = None
    avoided_colors: Optional[list[str]] = None
    style_preferences: Optional[list[str]] = None
    favorite_occasions: Optional[list[str]] = None
    body_type: Optional[str] = None
    onboarding_completed: Optional[bool] = None


class ProfileResponse(BaseModel):
    id: int
    user_id: int
    gender: Optional[str] = None
    age_range: Optional[str] = None
    budget_min: Optional[int] = None
    budget_max: Optional[int] = None
    preferred_colors: Optional[list[str]] = None
    avoided_colors: Optional[list[str]] = None
    style_preferences: Optional[list[str]] = None
    favorite_occasions: Optional[list[str]] = None
    body_type: Optional[str] = None
    onboarding_completed: bool
    created_at: datetime

    model_config = {"from_attributes": True}
