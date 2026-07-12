"""Tests for wardrobe endpoints."""
import pytest
from tests.conftest import register_and_login, auth_headers


@pytest.mark.asyncio
async def test_create_wardrobe_item(client):
    token, _ = await register_and_login(client)
    resp = await client.post("/api/wardrobe/items", json={
        "name": "Blue Shirt",
        "category": "shirt",
        "color_primary": "blue",
        "formality_level": "casual",
    }, headers=auth_headers(token))
    assert resp.status_code == 201
    data = resp.json()
    assert data["name"] == "Blue Shirt"
    assert data["category"] == "shirt"


@pytest.mark.asyncio
async def test_list_wardrobe_items(client):
    token, _ = await register_and_login(client)
    for name in ["Shirt 1", "Shirt 2", "Jeans 1"]:
        cat = "shirt" if "Shirt" in name else "jeans"
        await client.post("/api/wardrobe/items", json={
            "name": name, "category": cat,
        }, headers=auth_headers(token))
    resp = await client.get("/api/wardrobe/items", headers=auth_headers(token))
    assert resp.status_code == 200
    assert len(resp.json()) == 3


@pytest.mark.asyncio
async def test_filter_by_category(client):
    token, _ = await register_and_login(client)
    await client.post("/api/wardrobe/items", json={"name": "T1", "category": "shirt"}, headers=auth_headers(token))
    await client.post("/api/wardrobe/items", json={"name": "J1", "category": "jeans"}, headers=auth_headers(token))
    resp = await client.get("/api/wardrobe/items?category=shirt", headers=auth_headers(token))
    assert resp.status_code == 200
    items = resp.json()
    assert len(items) == 1
    assert items[0]["category"] == "shirt"


@pytest.mark.asyncio
async def test_update_item(client):
    token, _ = await register_and_login(client)
    create_resp = await client.post("/api/wardrobe/items", json={
        "name": "Old Name", "category": "shirt",
    }, headers=auth_headers(token))
    assert create_resp.status_code == 201
    item_id = create_resp.json()["id"]
    resp = await client.put(f"/api/wardrobe/items/{item_id}", json={
        "name": "New Name", "is_favorite": True,
    }, headers=auth_headers(token))
    assert resp.status_code == 200
    assert resp.json()["name"] == "New Name"
    assert resp.json()["is_favorite"] is True


@pytest.mark.asyncio
async def test_delete_item(client):
    token, _ = await register_and_login(client)
    create_resp = await client.post("/api/wardrobe/items", json={
        "name": "To Delete", "category": "shirt",
    }, headers=auth_headers(token))
    assert create_resp.status_code == 201
    item_id = create_resp.json()["id"]
    resp = await client.delete(f"/api/wardrobe/items/{item_id}", headers=auth_headers(token))
    assert resp.status_code == 204


@pytest.mark.asyncio
async def test_search_items(client):
    token, _ = await register_and_login(client)
    await client.post("/api/wardrobe/items", json={"name": "Navy Blazer", "category": "blazer"}, headers=auth_headers(token))
    await client.post("/api/wardrobe/items", json={"name": "Red Dress", "category": "dress"}, headers=auth_headers(token))
    resp = await client.get("/api/wardrobe/items?search=Navy", headers=auth_headers(token))
    assert resp.status_code == 200
    items = resp.json()
    assert len(items) == 1
    assert "Navy" in items[0]["name"]
