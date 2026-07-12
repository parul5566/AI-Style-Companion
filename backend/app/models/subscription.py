"""Subscription model."""
from datetime import datetime
from typing import Optional

from sqlalchemy import BigInteger, String, Boolean, DateTime, Integer, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Subscription(Base):
    __tablename__ = "subscriptions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("users.id"), unique=True, nullable=False)
    tier: Mapped[str] = mapped_column(String(20), nullable=False, default="free", server_default="free")
    tryon_credits_remaining: Mapped[int] = mapped_column(Integer, default=3, server_default="3")
    tryon_credits_monthly: Mapped[int] = mapped_column(Integer, default=3, server_default="3")
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, server_default="1")
    started_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    renews_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now()
    )

    user: Mapped["User"] = relationship(back_populates="subscription")


# Tier definitions
TIER_CONFIG = {
    "free": {"credits_monthly": 3, "features": ["basic_tagging", "basic_recommendation"]},
    "basic": {"credits_monthly": 10, "features": ["basic_tagging", "recommendation", "chat"]},
    "plus": {"credits_monthly": 25, "features": ["basic_tagging", "recommendation", "chat", "priority"]},
    "premium": {"credits_monthly": 100, "features": ["all", "priority", "exclusive"]},
}
