"""Wardrobe service — CRUD + filtering + AI tagging."""
import base64
import os
import uuid
from typing import Optional

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models.wardrobe import WardrobeItem
from app.schemas.wardrobe import WardrobeItemCreate, WardrobeItemUpdate
from app.services import ai_service


async def get_user_items(
    db: AsyncSession,
    user_id: int,
    category: Optional[str] = None,
    is_favorite: Optional[bool] = None,
    search: Optional[str] = None,
) -> list[WardrobeItem]:
    stmt = select(WardrobeItem).where(WardrobeItem.user_id == user_id)
    if category:
        stmt = stmt.where(WardrobeItem.category == category)
    if is_favorite is not None:
        stmt = stmt.where(WardrobeItem.is_favorite == is_favorite)
    if search:
        stmt = stmt.where(WardrobeItem.name.ilike(f"%{search}%"))
    stmt = stmt.order_by(WardrobeItem.created_at.desc())
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def get_item(db: AsyncSession, user_id: int, item_id: int) -> Optional[WardrobeItem]:
    result = await db.execute(
        select(WardrobeItem).where(WardrobeItem.id == item_id, WardrobeItem.user_id == user_id)
    )
    return result.scalar_one_or_none()


async def create_item(db: AsyncSession, user_id: int, payload: WardrobeItemCreate) -> WardrobeItem:
    item = WardrobeItem(
        user_id=user_id,
        name=payload.name,
        category=payload.category,
        subcategory=payload.subcategory,
        color_primary=payload.color_primary,
        color_secondary=payload.color_secondary,
        pattern=payload.pattern,
        fabric=payload.fabric,
        brand=payload.brand,
        formality_level=payload.formality_level,
        season=payload.season,
        purchase_price=payload.purchase_price,
    )
    db.add(item)
    await db.flush()
    return item


async def update_item(
    db: AsyncSession, user_id: int, item_id: int, payload: WardrobeItemUpdate
) -> Optional[WardrobeItem]:
    item = await get_item(db, user_id, item_id)
    if not item:
        return None
    update_data = payload.model_dump(exclude_unset=True)
    for key, val in update_data.items():
        setattr(item, key, val)
    await db.flush()
    return item


async def delete_item(db: AsyncSession, user_id: int, item_id: int) -> bool:
    item = await get_item(db, user_id, item_id)
    if not item:
        return False
    await db.delete(item)
    await db.flush()
    return True


async def save_upload(content: bytes, ext: str = ".jpg") -> str:
    """Save uploaded image and return its relative path."""
    filename = f"{uuid.uuid4().hex}{ext}"
    filepath = os.path.join(settings.UPLOAD_DIR, filename)
    with open(filepath, "wb") as f:
        f.write(content)
    return f"/uploads/{filename}"


async def tag_and_create_item(
    db: AsyncSession,
    user_id: int,
    image_bytes: bytes,
    image_ext: str = ".jpg",
) -> WardrobeItem:
    """Upload an image, AI-tag it, and create the wardrobe item."""
    # Save image
    rel_path = await save_upload(image_bytes, image_ext)

    # AI tag from image
    image_b64 = base64.b64encode(image_bytes).decode("utf-8")
    try:
        tags = await ai_service.tag_garment_from_image(image_b64)
    except Exception:
        # Fallback: try with a generic description
        try:
            tags = await ai_service.tag_garment_from_description("a clothing item")
        except Exception:
            tags = {"name": "New Item", "category": "other"}

    item = WardrobeItem(
        user_id=user_id,
        name=tags.get("name", "New Item"),
        category=tags.get("category", "other"),
        subcategory=tags.get("subcategory"),
        color_primary=tags.get("color_primary"),
        color_secondary=tags.get("color_secondary"),
        pattern=tags.get("pattern"),
        fabric=tags.get("fabric"),
        brand=tags.get("brand"),
        formality_level=tags.get("formality_level"),
        season=tags.get("season", "all_season"),
        image_path=rel_path,
        ai_tags=tags,
    )
    db.add(item)
    await db.flush()
    return item


async def get_item_counts(db: AsyncSession, user_id: int) -> dict[str, int]:
    """Return category counts for dashboard."""
    stmt = (
        select(WardrobeItem.category, func.count(WardrobeItem.id))
        .where(WardrobeItem.user_id == user_id)
        .group_by(WardrobeItem.category)
    )
    result = await db.execute(stmt)
    return {row[0]: row[1] for row in result.all()}


async def mark_as_worn(db: AsyncSession, item_id: int) -> None:
    """Increment times_worn and set last_worn_date to today."""
    from datetime import date
    result = await db.execute(
        select(WardrobeItem).where(WardrobeItem.id == item_id)
    )
    item = result.scalar_one_or_none()
    if item:
        item.times_worn = (item.times_worn or 0) + 1
        item.last_worn_date = date.today()
        await db.commit()
