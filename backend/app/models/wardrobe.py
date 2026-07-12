"""Wardrobe item model."""
from datetime import date, datetime
from decimal import Decimal
from typing import Optional

from sqlalchemy import BigInteger, String, Boolean, DateTime, Integer, Numeric, Date, ForeignKey, func
from sqlalchemy.dialects.mysql import JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class WardrobeItem(Base):
    __tablename__ = "wardrobe_items"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("users.id"), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    category: Mapped[str] = mapped_column(String(50), nullable=False)
    subcategory: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    color_primary: Mapped[Optional[str]] = mapped_column(String(30), nullable=True)
    color_secondary: Mapped[Optional[str]] = mapped_column(String(30), nullable=True)
    pattern: Mapped[Optional[str]] = mapped_column(String(30), nullable=True)
    fabric: Mapped[Optional[str]] = mapped_column(String(30), nullable=True)
    brand: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    formality_level: Mapped[Optional[str]] = mapped_column(String(30), nullable=True)
    season: Mapped[Optional[str]] = mapped_column(String(20), nullable=True, default="all_season")
    image_path: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    ai_tags: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    is_favorite: Mapped[bool] = mapped_column(Boolean, default=False, server_default="0")
    times_worn: Mapped[int] = mapped_column(Integer, default=0, server_default="0")
    last_worn_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    purchase_price: Mapped[Optional[Decimal]] = mapped_column(Numeric(10, 2), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now()
    )

    user: Mapped["User"] = relationship(back_populates="wardrobe_items")
    outfit_items = relationship("OutfitItem", back_populates="wardrobe_item")
