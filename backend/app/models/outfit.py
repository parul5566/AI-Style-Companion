"""Outfit and outfit-item models."""
from datetime import datetime
from decimal import Decimal
from typing import Optional

from sqlalchemy import BigInteger, String, Boolean, DateTime, Integer, Numeric, ForeignKey, Enum, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Outfit(Base):
    __tablename__ = "outfits"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("users.id"), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    occasion: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    weather_context: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    ai_confidence_score: Mapped[Optional[Decimal]] = mapped_column(Numeric(5, 2), nullable=True)
    is_ai_generated: Mapped[bool] = mapped_column(Boolean, default=False, server_default="0")
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now()
    )

    user: Mapped["User"] = relationship(back_populates="outfits")
    items = relationship("OutfitItem", back_populates="outfit", cascade="all, delete-orphan")
    feedback = relationship("OutfitFeedback", back_populates="outfit", cascade="all, delete-orphan")


class OutfitItem(Base):
    __tablename__ = "outfit_items"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    outfit_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("outfits.id"), nullable=False, index=True)
    wardrobe_item_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("wardrobe_items.id"), nullable=False)
    role: Mapped[str] = mapped_column(String(20), nullable=False)  # top, bottom, outer, footwear, accessory

    outfit: Mapped["Outfit"] = relationship(back_populates="items")
    wardrobe_item: Mapped["WardrobeItem"] = relationship(back_populates="outfit_items")


class OutfitFeedback(Base):
    __tablename__ = "outfit_feedback"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    outfit_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("outfits.id"), nullable=False)
    user_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("users.id"), nullable=False)
    feedback: Mapped[str] = mapped_column(String(20), nullable=False)  # accepted, rejected, maybe
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    outfit: Mapped["Outfit"] = relationship(back_populates="feedback")


from app.models.wardrobe import WardrobeItem
