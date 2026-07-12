"""Try-On schemas."""
from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class AvatarUploadResponse(BaseModel):
    avatar_photo_path: str
    message: str = "Avatar uploaded successfully"


class TryOnRequest(BaseModel):
    product_name: str
    product_category: Optional[str] = None
    product_image_url: Optional[str] = None
    vendor: Optional[str] = None


class TryOnResponse(BaseModel):
    id: int
    product_name: str
    product_category: Optional[str] = None
    product_image_url: Optional[str] = None
    vendor: Optional[str] = None
    result_image_path: Optional[str] = None
    credits_used: int = 1
    credits_remaining: int
    status: str = "completed"
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class TryOnHistoryItem(BaseModel):
    id: int
    product_name: str
    product_image_url: Optional[str] = None
    result_image_path: Optional[str] = None
    status: str
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True
