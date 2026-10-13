"""Unit tests that need no database: health and request validation."""
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health_returns_ok():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_stock_rejects_negative_quantity():
    response = client.put("/inventory/shirt-001", json={"quantity": -1})
    assert response.status_code == 422


def test_stock_requires_quantity():
    response = client.put("/inventory/shirt-001", json={})
    assert response.status_code == 422