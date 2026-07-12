"""Weather service — fetches from Open-Meteo API (free, no API key required)."""
import logging
from typing import Optional

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.weather import WeatherSnapshot

logger = logging.getLogger(__name__)

OPEN_METEO_GEO_URL = "https://geocoding-api.open-meteo.com/v1/search"
OPEN_METEO_WEATHER_URL = "https://api.open-meteo.com/v1/forecast"


async def _geocode(city: str) -> Optional[tuple[float, float]]:
    """Get lat/lon for a city name."""
    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.get(
            OPEN_METEO_GEO_URL, params={"name": city, "count": 1, "language": "en", "format": "json"}
        )
        resp.raise_for_status()
        data = resp.json()
        results = data.get("results", [])
        if not results:
            return None
        r = results[0]
        return r["latitude"], r["longitude"]


async def get_weather(db: AsyncSession, city: str) -> Optional[WeatherSnapshot]:
    """Fetch current weather for a city and cache it."""
    lat_lon = await _geocode(city)
    if not lat_lon:
        return None
    lat, lon = lat_lon

    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.get(
            OPEN_METEO_WEATHER_URL,
            params={
                "latitude": lat,
                "longitude": lon,
                "current": "temperature_2m,relative_humidity_2m,apparent_temperature,is_day,wind_speed_10m,weather_code",
                "timezone": "auto",
            },
        )
        resp.raise_for_status()
        data = resp.json()

    current = data.get("current", {})
    code = current.get("weather_code", 0)
    condition_text = _weather_code_text(code)

    snapshot = WeatherSnapshot(
        city=city,
        temperature_c=current.get("temperature_2m", 20),
        feels_like_c=current.get("apparent_temperature"),
        humidity=current.get("relative_humidity_2m"),
        wind_kph=(current.get("wind_speed_10m", 0) or 0),
        condition_code=str(code),
        condition_text=condition_text,
        is_day=bool(current.get("is_day", 1)),
    )
    db.add(snapshot)
    await db.flush()
    return snapshot


def _weather_code_text(code: int) -> str:
    """Map WMO weather code to human-readable text."""
    mapping = {
        0: "Clear sky",
        1: "Mainly clear",
        2: "Partly cloudy",
        3: "Overcast",
        45: "Foggy",
        48: "Depositing rime fog",
        51: "Light drizzle",
        53: "Moderate drizzle",
        55: "Dense drizzle",
        61: "Slight rain",
        63: "Moderate rain",
        65: "Heavy rain",
        71: "Slight snow fall",
        73: "Moderate snow fall",
        75: "Heavy snow fall",
        80: "Slight rain showers",
        81: "Moderate rain showers",
        82: "Violent rain showers",
        95: "Thunderstorm",
        96: "Thunderstorm with slight hail",
        99: "Thunderstorm with heavy hail",
    }
    return mapping.get(code, f"Code {code}")
