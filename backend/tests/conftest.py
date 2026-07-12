"""Shared test fixtures."""
import uuid

import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.database import Base
from app.dependencies import get_db
from app.main import app
from app.config import settings
from app.models import *  # noqa: F401, F403


@pytest_asyncio.fixture
async def test_engine():
    engine = create_async_engine(settings.database_url, echo=False)
    yield engine
    await engine.dispose()


@pytest_asyncio.fixture
async def client(test_engine):
    """Async HTTP client for testing API endpoints."""
    session_factory = async_sessionmaker(test_engine, class_=AsyncSession, expire_on_commit=False)

    async def _get_test_db():
        async with session_factory() as session:
            try:
                yield session
                await session.commit()
            except Exception:
                await session.rollback()
                raise

    app.dependency_overrides[get_db] = _get_test_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
    app.dependency_overrides.clear()


def _unique_email() -> str:
    return f"test-{uuid.uuid4().hex[:8]}@style.com"


async def register_and_login(client: AsyncClient, email: str | None = None) -> tuple[str, str]:
    """Register a user and return (token, email)."""
    email = email or _unique_email()
    resp = await client.post("/api/auth/register", json={
        "email": email,
        "password": "password123",
        "full_name": "Test User",
    })
    if resp.status_code == 409:
        # User exists from previous run — delete and re-register
        # Just try logging in
        pass
    resp = await client.post("/api/auth/login", json={
        "email": email,
        "password": "password123",
    })
    if resp.status_code != 200:
        # Re-register with a new email
        email = _unique_email()
        await client.post("/api/auth/register", json={
            "email": email,
            "password": "password123",
            "full_name": "Test User",
        })
        resp = await client.post("/api/auth/login", json={
            "email": email,
            "password": "password123",
        })
    assert resp.status_code == 200, f"Login failed: {resp.text}"
    return resp.json()["access_token"], email


def auth_headers(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}
