"""Weather snapshot model."""
from datetime import datetime
from decimal import Decimal
from typing import Optional

from sqlalchemy import String, DateTime, Integer, Numeric, Boolean, func
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class WeatherSnapshot(Base):
    __tablename__ = "weather_snapshots"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    city: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    temperature_c: Mapped[Decimal] = mapped_column(Numeric(5, 2), nullable=False)
    feels_like_c: Mapped[Optional[Decimal]] = mapped_column(Numeric(5, 2), nullable=True)
    humidity: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    wind_kph: Mapped[Optional[Decimal]] = mapped_column(Numeric(5, 2), nullable=True)
    condition_code: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    condition_text: Mapped[str] = mapped_column(String(100), nullable=False)
    is_day: Mapped[bool] = mapped_column(Boolean, default=True)
    fetched_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
