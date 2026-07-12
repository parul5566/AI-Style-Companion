"""Wardrobe item schemas."""
from datetime import date, datetime
from decimal import Decimal
from typing import Optional
from pydantic import BaseModel, Field


class WardrobeItemCreate(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    category: str = Field(min_length=1, max_length=50)
    subcategory: Optional[str] = None
    color_primary: Optional[str] = None
    color_secondary: Optional[str] = None
    pattern: Optional[str] = None
    fabric: Optional[str] = None
    brand: Optional[str] = None
    formality_level: Optional[str] = None
    season: Optional[str] = "all_season"
    purchase_price: Optional[Decimal] = None


class WardrobeItemUpdate(BaseModel):
    name: Optional[str] = None
    category: Optional[str] = None
    subcategory: Optional[str] = None
    color_primary: Optional[str] = None
    color_secondary: Optional[str] = None
    pattern: Optional[str] = None
    fabric: Optional[str] = None
    brand: Optional[str] = None
    formality_level: Optional[str] = None
    season: Optional[str] = None
    is_favorite: Optional[bool] = None
    purchase_price: Optional[Decimal] = None


class WardrobeItemResponse(BaseModel):
    id: int
    user_id: int
    name: str
    category: str
    subcategory: Optional[str] = None
    color_primary: Optional[str] = None
    color_secondary: Optional[str] = None
    pattern: Optional[str] = None
    fabric: Optional[str] = None
    brand: Optional[str] = None
    formality_level: Optional[str] = None
    season: Optional[str] = None
    image_path: Optional[str] = None
    ai_tags: Optional[dict] = None
    is_favorite: bool
    times_worn: int
    last_worn_date: Optional[date] = None
    purchase_price: Optional[Decimal] = None
    created_at: datetime

    model_config = {"from_attributes": True}


class AITagResult(BaseModel):
    """Result of AI garment analysis."""
    name: str
    category: str
    subcategory: Optional[str] = None
    color_primary: Optional[str] = None
    color_secondary: Optional[str] = None
    pattern: Optional[str] = None
    fabric: Optional[str] = None
    brand: Optional[str] = None
    formality_level: Optional[str] = None
    season: Optional[str] = None
    description: Optional[str] = None
