import pytest
from unittest.mock import patch
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_auth_me_success():
    """Test /api/auth/me returns token data when authenticated."""
    mock_user = {"uid": "test_uid_123", "email": "test@example.com"}
    
    with patch("app.api.deps.FirebaseService.verify_token", return_value=mock_user):
        response = client.get(
            "/api/auth/me",
            headers={"Authorization": "Bearer fake_valid_token"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "authenticated"
        assert data["uid"] == "test_uid_123"
        assert data["email"] == "test@example.com"
        assert data["token_data"] == mock_user

def test_auth_me_unauthorized():
    """Test /api/auth/me returns 401/403 when not authenticated."""
    response = client.get("/api/auth/me")
    assert response.status_code in (401, 403)

def test_auth_me_invalid_token():
    """Test /api/auth/me returns 401 when token is invalid."""
    from app.services.firebase import FirebaseServiceError
    with patch("app.api.deps.FirebaseService.verify_token", side_effect=FirebaseServiceError("Invalid token")):
        response = client.get(
            "/api/auth/me",
            headers={"Authorization": "Bearer invalid_token"}
        )
        # HTTPException with status_code=401 is raised in get_current_user
        assert response.status_code == 401


def test_auth_me_missing_uid():
    """Test /api/auth/me returns 401 when token lacks a uid."""
    with patch("app.api.deps.FirebaseService.verify_token", return_value={"email": "test@example.com"}):
        response = client.get(
            "/api/auth/me",
            headers={"Authorization": "Bearer fake_valid_token"}
        )
        assert response.status_code == 401
