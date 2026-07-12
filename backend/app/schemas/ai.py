"""AI schemas."""
from typing import Optional
from pydantic import BaseModel, Field


class AITagRequest(BaseModel):
    """Request to tag a garment image."""
    pass  # image is sent as multipart form, no JSON body needed


class AITagResponse(BaseModel):
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
    image_path: Optional[str] = None


class MissingPieceRequest(BaseModel):
    event_type: str = Field(description="e.g. wedding, interview, date, work")
    dress_code: Optional[str] = None
    budget_max: Optional[int] = None


class MissingPieceItem(BaseModel):
    category: str
    name: str
    reason: str
    priority: str  # high, medium, low
    suggested_price_range: Optional[str] = None


class MissingPieceResponse(BaseModel):
    event_type: str
    have: list[str] = []
    missing: list[MissingPieceItem] = []
    summary: Optional[str] = None
