"""Dashboard schemas."""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel

from app.schemas.outfit import OutfitResponse
from app.schemas.ai import MissingPieceItem


class WeatherInfo(BaseModel):
    city: str
    temperature_c: float
    feels_like_c: Optional[float] = None
    condition_text: str
    humidity: Optional[int] = None
    wind_kph: Optional[float] = None


class WardrobeStats(BaseModel):
    total_items: int
    by_category: dict[str, int]
    favorites_count: int
    recently_worn_count: int


class DashboardSummary(BaseModel):
    weather: Optional[WeatherInfo] = None
    today_outfit: Optional[OutfitResponse] = None
    wardrobe_stats: WardrobeStats
    missing_items: list[MissingPieceItem] = []
    upcoming_events: list[dict] = []
    subscription_tier: str = "free"
    tryon_credits: int = 0
