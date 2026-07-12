"""Authentication service."""
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User, UserProfile
from app.models.subscription import Subscription
from app.utils.security import hash_password, verify_password, create_access_token


async def get_user_by_email(db: AsyncSession, email: str) -> User | None:
    result = await db.execute(select(User).where(User.email == email))
    return result.scalar_one_or_none()


async def register_user(db: AsyncSession, email: str, password: str, full_name: str) -> User:
    existing = await get_user_by_email(db, email)
    if existing:
        raise ValueError("Email already registered")

    user = User(
        email=email,
        password_hash=hash_password(password),
        full_name=full_name,
    )
    db.add(user)
    await db.flush()

    # Auto-create empty profile + free subscription
    profile = UserProfile(user_id=user.id)
    db.add(profile)
    sub = Subscription(user_id=user.id, tier="free", tryon_credits_remaining=3, tryon_credits_monthly=3)
    db.add(sub)
    await db.flush()
    return user


async def authenticate_user(db: AsyncSession, email: str, password: str) -> User | None:
    user = await get_user_by_email(db, email)
    if not user or not verify_password(password, user.password_hash):
        return None
    return user


def create_token_for_user(user: User) -> str:
    return create_access_token(str(user.id))
