"""Shopping schemas."""
from pydantic import BaseModel
from typing import Optional, List
from decimal import Decimal


class ShoppingProductResponse(BaseModel):
    id: int
    name: str
    category: str
    brand: Optional[str] = None
    price: Decimal
    currency: str = "USD"
    image_url: Optional[str] = None
    product_url: str = "#"
    vendor: str
    tags: Optional[dict] = None

    class Config:
        from_attributes = True


class WishlistResponse(BaseModel):
    id: int
    product: ShoppingProductResponse

    class Config:
        from_attributes = True
