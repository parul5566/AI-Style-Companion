"""Wardrobe routes: CRUD + search + AI-tag upload."""
from typing import Optional

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_db, get_current_user
from app.models.user import User
from app.models.wardrobe import WardrobeItem
from app.schemas.wardrobe import (
    WardrobeItemCreate,
    WardrobeItemUpdate,
    WardrobeItemResponse,
    AITagResult,
)
from app.services import wardrobe_service

router = APIRouter(prefix="/wardrobe", tags=["wardrobe"])

ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}


@router.get("/items", response_model=list[WardrobeItemResponse])
async def list_items(
    category: Optional[str] = Query(None),
    is_favorite: Optional[bool] = Query(None),
    search: Optional[str] = Query(None),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await wardrobe_service.get_user_items(db, user.id, category, is_favorite, search)


@router.post("/items", response_model=WardrobeItemResponse, status_code=201)
async def create_item(
    payload: WardrobeItemCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await wardrobe_service.create_item(db, user.id, payload)


@router.get("/items/{item_id}", response_model=WardrobeItemResponse)
async def get_item(
    item_id: int,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    item = await wardrobe_service.get_item(db, user.id, item_id)
    if not item:
        raise HTTPException(404, "Item not found")
    return item


@router.put("/items/{item_id}", response_model=WardrobeItemResponse)
async def update_item(
    item_id: int,
    payload: WardrobeItemUpdate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    item = await wardrobe_service.update_item(db, user.id, item_id, payload)
    if not item:
        raise HTTPException(404, "Item not found")
    return item


@router.delete("/items/{item_id}", status_code=204)
async def delete_item(
    item_id: int,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    deleted = await wardrobe_service.delete_item(db, user.id, item_id)
    if not deleted:
        raise HTTPException(404, "Item not found")
    return None


@router.post("/items/upload", response_model=WardrobeItemResponse, status_code=201)
async def upload_and_tag(
    file: UploadFile = File(...),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Upload a garment image, AI-tag it, and create a wardrobe item."""
    ext = "." + (file.filename.rsplit(".", 1)[-1].lower() if "." in (file.filename or "") else "jpg")
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(400, f"Unsupported file type. Allowed: {ALLOWED_EXTENSIONS}")

    content = await file.read()
    if not content:
        raise HTTPException(400, "Empty file")

    item = await wardrobe_service.tag_and_create_item(db, user.id, content, ext)
    return item


@router.post("/items/{item_id}/wear", response_model=WardrobeItemResponse)
async def mark_item_worn(
    item_id: int,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Mark an item as worn today — increments times_worn, updates last_worn_date."""
    from datetime import date
    item = await wardrobe_service.get_item(db, user.id, item_id)
    if not item:
        raise HTTPException(404, "Item not found")
    await wardrobe_service.mark_as_worn(db, item_id)
    updated = await wardrobe_service.get_item(db, user.id, item_id)
    return updated
