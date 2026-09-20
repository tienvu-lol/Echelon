import pytest
from fastapi.testclient import TestClient

from app.api.deps import get_current_user
from app.main import app


def _authenticate(uid: str = "student1") -> None:
    app.dependency_overrides[get_current_user] = lambda: {"uid": uid}


@pytest.fixture(autouse=True)
def clear_dependency_overrides():
    app.dependency_overrides.clear()
    yield
    app.dependency_overrides.clear()

def test_swipe_without_auth(client: TestClient):
    # Missing auth header should 401
    response = client.post("/api/swipes", json={"opportunity_id": "opp1", "direction": "right"})
    assert response.status_code == 401

def test_swipe_nonexistent_opportunity(client: TestClient, mocker):
    _authenticate()
    mocker.patch("app.services.databricks_service.get_opportunity", return_value=None)
    
    response = client.post("/api/swipes", json={"opportunity_id": "missing_opp", "direction": "right"}, headers={"Authorization": "Bearer fake_token"})
    assert response.status_code == 404

def test_right_swipe(client: TestClient, mocker):
    _authenticate()
    mocker.patch("app.services.databricks_service.get_opportunity", return_value={"id": "opp1", "title": "Test"})
    mock_save_swipe = mocker.patch("app.services.databricks_service.save_swipe")
    mock_save_saved = mocker.patch("app.services.databricks_service.save_saved_opportunity")
    
    response = client.post("/api/swipes", json={"opportunity_id": "opp1", "direction": "right"}, headers={"Authorization": "Bearer fake_token"})
    assert response.status_code == 200
    mock_save_swipe.assert_called_once_with("student1", "opp1", "right")
    mock_save_saved.assert_called_once_with("student1", "opp1")

def test_left_swipe(client: TestClient, mocker):
    _authenticate()
    mocker.patch("app.services.databricks_service.get_opportunity", return_value={"id": "opp1", "title": "Test"})
    mock_save_swipe = mocker.patch("app.services.databricks_service.save_swipe")
    mock_remove_saved = mocker.patch("app.services.databricks_service.remove_saved_opportunity")
    
    response = client.post("/api/swipes", json={"opportunity_id": "opp1", "direction": "left"}, headers={"Authorization": "Bearer fake_token"})
    assert response.status_code == 200
    mock_save_swipe.assert_called_once_with("student1", "opp1", "left")
    mock_remove_saved.assert_called_once_with("student1", "opp1")

def test_get_saved_opportunities(client: TestClient, mocker):
    _authenticate()
    # Returning a mock opportunity dict that matches the canonical schema slightly
    mocker.patch("app.services.databricks_service.get_saved_opportunities", return_value=[])
    
    response = client.get("/api/saved", headers={"Authorization": "Bearer fake_token"})
    assert response.status_code == 200
    assert response.json()["student_id"] == "student1"
    assert response.json()["opportunities"] == []

def test_delete_saved_opportunity(client: TestClient, mocker):
    _authenticate()
    mocker.patch("app.services.databricks_service.get_opportunity", return_value={"id": "opp1", "title": "Test"})
    mock_remove = mocker.patch("app.services.databricks_service.remove_saved_opportunity")
    
    response = client.delete("/api/saved/opp1", headers={"Authorization": "Bearer fake_token"})
    assert response.status_code == 200
    mock_remove.assert_called_once_with("student1", "opp1")
