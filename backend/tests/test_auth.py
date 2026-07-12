"""Tests for authentication endpoints."""
import pytest
import uuid
from tests.conftest import register_and_login, auth_headers


@pytest.mark.asyncio
async def test_register_success(client):
    email = f"new-{uuid.uuid4().hex[:8]}@style.com"
    resp = await client.post("/api/auth/register", json={
        "email": email,
        "password": "password123",
        "full_name": "New User",
    })
    assert resp.status_code == 201
    data = resp.json()
    assert "access_token" in data
    assert data["email"] == email
    assert data["full_name"] == "New User"


@pytest.mark.asyncio
async def test_register_duplicate(client):
    email = f"dup-{uuid.uuid4().hex[:8]}@style.com"
    resp1 = await client.post("/api/auth/register", json={
        "email": email,
        "password": "password123",
        "full_name": "Dup User",
    })
    assert resp1.status_code == 201
    resp2 = await client.post("/api/auth/register", json={
        "email": email,
        "password": "password123",
        "full_name": "Dup User",
    })
    assert resp2.status_code == 409


@pytest.mark.asyncio
async def test_login_success(client):
    token, email = await register_and_login(client)
    assert token  # got a JWT


@pytest.mark.asyncio
async def test_login_wrong_password(client):
    token, email = await register_and_login(client)
    resp = await client.post("/api/auth/login", json={
        "email": email,
        "password": "wrongpassword",
    })
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_me_requires_auth(client):
    resp = await client.get("/api/auth/me")
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_me_with_token(client):
    token, _ = await register_and_login(client)
    resp = await client.get("/api/auth/me", headers=auth_headers(token))
    assert resp.status_code == 200
    assert "@" in resp.json()["email"]
