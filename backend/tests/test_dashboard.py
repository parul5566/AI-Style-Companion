"""Tests for dashboard and subscription endpoints."""
import pytest
from tests.conftest import register_and_login, auth_headers


@pytest.mark.asyncio
async def test_dashboard_summary(client):
    token, _ = await register_and_login(client)
    resp = await client.get("/api/dashboard/summary?city=London", headers=auth_headers(token))
    assert resp.status_code == 200
    data = resp.json()
    assert "wardrobe_stats" in data
    assert "subscription_tier" in data
    assert data["subscription_tier"] == "free"


@pytest.mark.asyncio
async def test_dashboard_with_items(client):
    token, _ = await register_and_login(client)
    await client.post("/api/wardrobe/items", json={"name": "Item 1", "category": "shirt"}, headers=auth_headers(token))
    await client.post("/api/wardrobe/items", json={"name": "Item 2", "category": "jeans"}, headers=auth_headers(token))
    resp = await client.get("/api/dashboard/summary", headers=auth_headers(token))
    assert resp.status_code == 200
    data = resp.json()
    assert data["wardrobe_stats"]["total_items"] == 2


@pytest.mark.asyncio
async def test_get_subscription(client):
    token, _ = await register_and_login(client)
    resp = await client.get("/api/subscriptions", headers=auth_headers(token))
    assert resp.status_code == 200
    data = resp.json()
    assert data["tier"] == "free"
    assert data["tryon_credits_remaining"] >= 0


@pytest.mark.asyncio
async def test_get_tiers(client):
    token, _ = await register_and_login(client)
    resp = await client.get("/api/subscriptions/tiers", headers=auth_headers(token))
    assert resp.status_code == 200
    tiers = resp.json()
    assert len(tiers) == 4
    assert any(t["name"] == "free" for t in tiers)
    assert any(t["name"] == "premium" for t in tiers)


@pytest.mark.asyncio
async def test_update_tier(client):
    token, _ = await register_and_login(client)
    resp = await client.put("/api/subscriptions/tier", json={"tier": "plus"}, headers=auth_headers(token))
    assert resp.status_code == 200
    data = resp.json()
    assert data["tier"] == "plus"
    assert data["tryon_credits_monthly"] == 25
