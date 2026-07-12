"""Shopping routes — browse products, filter by category, wishlist."""
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.dependencies import get_db, get_current_user
from app.models.user import User
from app.models.shopping import ShoppingProduct, ShoppingWishlist
from app.schemas.shopping import ShoppingProductResponse, WishlistResponse

router = APIRouter(prefix="/shopping", tags=["shopping"])


@router.get("/products", response_model=list[ShoppingProductResponse])
async def list_products(
    category: Optional[str] = Query(None),
    search: Optional[str] = Query(None),
    min_price: Optional[float] = Query(None),
    max_price: Optional[float] = Query(None),
    limit: int = Query(50, le=100),
    offset: int = Query(0),
    _user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Browse all vendor products with optional filters."""
    stmt = select(ShoppingProduct)

    if category:
        stmt = stmt.where(ShoppingProduct.category == category)
    if search:
        stmt = stmt.where(ShoppingProduct.name.contains(search))
    if min_price is not None:
        stmt = stmt.where(ShoppingProduct.price >= min_price)
    if max_price is not None:
        stmt = stmt.where(ShoppingProduct.price <= max_price)

    stmt = stmt.order_by(ShoppingProduct.category, ShoppingProduct.price).limit(limit).offset(offset)
    result = await db.execute(stmt)
    return result.scalars().all()


@router.get("/products/category/{category}", response_model=list[ShoppingProductResponse])
async def list_by_category(
    category: str,
    _user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get all products in a specific category."""
    result = await db.execute(
        select(ShoppingProduct)
        .where(ShoppingProduct.category == category)
        .order_by(ShoppingProduct.price)
    )
    return result.scalars().all()


@router.get("/products/{product_id}", response_model=ShoppingProductResponse)
async def get_product(
    product_id: int,
    _user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get a single product."""
    result = await db.execute(
        select(ShoppingProduct).where(ShoppingProduct.id == product_id)
    )
    product = result.scalar_one_or_none()
    if not product:
        raise HTTPException(404, "Product not found")
    return product


@router.get("/products/by-category/{category}", response_model=list[ShoppingProductResponse])
async def recommend_products_for_gap(
    category: str,
    limit: int = Query(5, le=20),
    _user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get recommended products to fill a wardrobe gap (used by missing piece flow)."""
    result = await db.execute(
        select(ShoppingProduct)
        .where(ShoppingProduct.category == category)
        .order_by(ShoppingProduct.price)
        .limit(limit)
    )
    return result.scalars().all()


@router.get("/categories")
async def get_categories(
    _user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get all product categories with counts."""
    result = await db.execute(
        select(
            ShoppingProduct.category,
            func.count(ShoppingProduct.id).label("count")
        )
        .group_by(ShoppingProduct.category)
    )
    return [{"category": row[0], "count": row[1]} for row in result]


# ─── Wishlist ─────────────────────────────────────

@router.get("/wishlist", response_model=list[WishlistResponse])
async def get_wishlist(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get user's wishlist."""
    result = await db.execute(
        select(ShoppingWishlist)
        .options(selectinload(ShoppingWishlist.product))
        .where(ShoppingWishlist.user_id == user.id)
        .order_by(ShoppingWishlist.created_at.desc())
    )
    return result.scalars().all()


@router.post("/wishlist/{product_id}", status_code=201)
async def add_to_wishlist(
    product_id: int,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Add a product to wishlist."""
    # Check product exists
    result = await db.execute(
        select(ShoppingProduct).where(ShoppingProduct.id == product_id)
    )
    if not result.scalar_one_or_none():
        raise HTTPException(404, "Product not found")

    # Check if already wishlisted
    existing = await db.execute(
        select(ShoppingWishlist)
        .where(
            ShoppingWishlist.user_id == user.id,
            ShoppingWishlist.product_id == product_id,
        )
    )
    if existing.scalar_one_or_none():
        return {"status": "already_wishlisted", "product_id": product_id}

    entry = ShoppingWishlist(user_id=user.id, product_id=product_id)
    db.add(entry)
    await db.commit()
    return {"status": "added", "product_id": product_id}


@router.delete("/wishlist/{product_id}", status_code=204)
async def remove_from_wishlist(
    product_id: int,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Remove a product from wishlist."""
    result = await db.execute(
        select(ShoppingWishlist)
        .where(
            ShoppingWishlist.user_id == user.id,
            ShoppingWishlist.product_id == product_id,
        )
    )
    entry = result.scalar_one_or_none()
    if entry:
        await db.delete(entry)
        await db.commit()
    return None
