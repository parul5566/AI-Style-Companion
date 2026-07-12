"""Outfit schemas."""
from datetime import datetime
from decimal import Decimal
from typing import Optional
from pydantic import BaseModel, Field

from app.schemas.wardrobe import WardrobeItemResponse


class OutfitItemSlot(BaseModel):
    role: str  # top, bottom, outer, footwear, accessory
    item: WardrobeItemResponse


class OutfitRecommendationRequest(BaseModel):
    occasion: Optional[str] = Field(default="casual", description="e.g. work, date, wedding, interview")
    weather_temp_c: Optional[float] = None
    weather_condition: Optional[str] = None
    city: Optional[str] = None


class OutfitResponse(BaseModel):
    id: Optional[int] = None
    name: str
    occasion: Optional[str] = None
    weather_context: Optional[str] = None
    ai_confidence_score: Optional[Decimal] = None
    is_ai_generated: bool = False
    items: list[OutfitItemSlot] = []
    ai_reasoning: Optional[str] = None
    created_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


class OutfitFeedbackRequest(BaseModel):
    feedback: str = Field(pattern="^(accepted|rejected|maybe)$")
