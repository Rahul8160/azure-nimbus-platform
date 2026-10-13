"""Unit tests that need no database: health and request validation."""
from fastapi.testclient import TestClient

from app.main import app

# Not used as a context manager, so the startup hook (database init) does not run
client = TestClient(app)


def test_health_returns_ok():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_order_rejects_zero_quantity():
    response = client.post("/orders", json={"product_id": "shirt-001", "quantity": 0})
    assert response.status_code == 422


def test_order_rejects_quantity_over_limit():
    response = client.post("/orders", json={"product_id": "shirt-001", "quantity": 101})
    assert response.status_code == 422


def test_order_requires_product_id():
    response = client.post("/orders", json={"quantity": 1})
    assert response.status_code == 422