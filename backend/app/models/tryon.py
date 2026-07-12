"""Try-On model — stores avatar renders and credit consumption."""
from datetime import datetime
from typing import Optional

from sqlalchemy import BigInteger, String, DateTime, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class TryOnRender(Base):
    __tablename__ = "tryon_renders"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("users.id"), nullable=False)
    product_name: Mapped[str] = mapped_column(String(200), nullable=False)
    product_category: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    product_image_url: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    vendor: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    result_image_path: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    credits_used: Mapped[int] = mapped_column(default=1, server_default="1")
    status: Mapped[str] = mapped_column(String(20), default="completed", server_default="completed")
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    user: Mapped["User"] = relationship(back_populates="tryon_renders")
