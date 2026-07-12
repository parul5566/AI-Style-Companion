"""Weather routes."""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_db, get_current_user
from app.models.user import User
from app.schemas.dashboard import WeatherInfo
from app.services import weather_service

router = APIRouter(prefix="/weather", tags=["weather"])


@router.get("", response_model=WeatherInfo)
async def get_weather(
    city: str = Query(..., description="City name"),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    snap = await weather_service.get_weather(db, city)
    if not snap:
        raise HTTPException(404, f"City '{city}' not found")
    return WeatherInfo(
        city=snap.city,
        temperature_c=float(snap.temperature_c),
        feels_like_c=float(snap.feels_like_c) if snap.feels_like_c else None,
        condition_text=snap.condition_text,
        humidity=snap.humidity,
        wind_kph=float(snap.wind_kph) if snap.wind_kph else None,
    )
