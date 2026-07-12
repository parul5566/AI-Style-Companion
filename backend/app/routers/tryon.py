"""Try-On routes — avatar upload, render, credit gating, history."""
import os
import uuid

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_db, get_current_user
from app.models.user import User, UserProfile
from app.models.tryon import TryOnRender
from app.models.subscription import Subscription
from app.schemas.tryon import AvatarUploadResponse, TryOnRequest, TryOnResponse, TryOnHistoryItem
from app.config import settings

router = APIRouter(prefix="/tryon", tags=["tryon"])

ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}


@router.post("/avatar", response_model=AvatarUploadResponse)
async def upload_avatar(
    file: UploadFile = File(...),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Upload a full-body avatar photo for try-on."""
    ext = "." + (file.filename.rsplit(".", 1)[-1].lower()
                 if "." in (file.filename or "") else "jpg")
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(400, f"Unsupported file type. Allowed: {ALLOWED_EXTENSIONS}")

    content = await file.read()
    if not content:
        raise HTTPException(400, "Empty file")

    filename = f"avatar_{user.id}_{uuid.uuid4().hex}{ext}"
    filepath = os.path.join(settings.UPLOAD_DIR, filename)
    with open(filepath, "wb") as f:
        f.write(content)

    rel_path = f"/uploads/{filename}"

    # Save to profile
    result = await db.execute(
        select(UserProfile).where(UserProfile.user_id == user.id)
    )
    profile = result.scalar_one_or_none()
    if profile:
        profile.avatar_photo_path = rel_path
    else:
        profile = UserProfile(user_id=user.id, avatar_photo_path=rel_path)
        db.add(profile)
    await db.commit()

    return AvatarUploadResponse(avatar_photo_path=rel_path)


@router.get("/avatar")
async def get_avatar(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get the user's avatar photo path."""
    result = await db.execute(
        select(UserProfile).where(UserProfile.user_id == user.id)
    )
    profile = result.scalar_one_or_none()
    if not profile or not profile.avatar_photo_path:
        raise HTTPException(404, "No avatar uploaded. Upload one first.")
    return {"avatar_photo_path": profile.avatar_photo_path}


@router.post("/render", response_model=TryOnResponse)
async def render_tryon(
    request: TryOnRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Simulate a try-on render. Deducts 1 credit."""
    # Get subscription + check credits
    sub_result = await db.execute(
        select(Subscription).where(Subscription.user_id == user.id)
    )
    sub = sub_result.scalar_one_or_none()
    if not sub:
        sub = Subscription(user_id=user.id)
        db.add(sub)
        await db.flush()

    if sub.tryon_credits_remaining <= 0:
        raise HTTPException(403, "No try-on credits remaining. Upgrade your plan.")

    # Deduct credit
    sub.tryon_credits_remaining -= 1

    # Create render record (mock result — in production, this calls an AI vision service)
    render = TryOnRender(
        user_id=user.id,
        product_name=request.product_name,
        product_category=request.product_category,
        product_image_url=request.product_image_url,
        vendor=request.vendor,
        result_image_path=request.product_image_url,  # stub: return the product image as "render"
        credits_used=1,
        status="completed",
    )
    db.add(render)
    await db.commit()
    await db.refresh(render)

    return TryOnResponse(
        id=render.id,
        product_name=render.product_name,
        product_category=render.product_category,
        product_image_url=render.product_image_url,
        vendor=render.vendor,
        result_image_path=render.result_image_path,
        credits_used=render.credits_used,
        credits_remaining=sub.tryon_credits_remaining,
        status=render.status,
        created_at=render.created_at,
    )


@router.get("/history", response_model=list[TryOnHistoryItem])
async def tryon_history(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get try-on render history."""
    result = await db.execute(
        select(TryOnRender)
        .where(TryOnRender.user_id == user.id)
        .order_by(TryOnRender.created_at.desc())
        .limit(20)
    )
    return result.scalars().all()
