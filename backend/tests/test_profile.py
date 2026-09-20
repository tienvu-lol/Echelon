import pytest
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_parse_profile_requires_auth():
    """Ensure the profile parse route requires authentication."""
    response = client.post(
        "/api/profile/parse",
        files={"resume": ("test.pdf", b"dummy content", "application/pdf")}
    )
    assert response.status_code in (401, 403)  # HTTPBearer typically returns 401 or 403

def test_parse_profile_success():
    """Test successful resume parsing with mocked auth and Gemini."""
    # Mock the get_current_user dependency directly, or mock the verify_token
    # We will mock verify_token to simulate a logged-in user
    mock_user = {"uid": "user123"}
    
    from app.models.student import StudentProfile
    mock_parsed = StudentProfile(
        major="Computer Science",
        class_year="Junior",
        skills=["Python", "Swift"],
        interests=["Mobile Dev"],
        coursework=["Algorithms"],
        experience=["Intern at Tech Corp"]
    )
    
    with patch("app.api.deps.FirebaseService.verify_token", return_value=mock_user):
        with patch("app.api.profile.parse_resume", return_value=mock_parsed):
            with patch("app.api.profile.save_student_profile") as mock_save:
                response = client.post(
                    "/api/profile/parse",
                    headers={"Authorization": "Bearer fake_token"},
                    files={"resume": ("test.pdf", b"dummy content", "application/pdf")},
                    data={"bio": "I am a student", "interests": "Coding"}
                )
                
                assert response.status_code == 200
                data = response.json()
                assert data["major"] == "Computer Science"
                assert data["class_year"] == "Junior"
                assert "Python" in data["skills"]
                
                # Check persistence
                mock_save.assert_called_once()
                args = mock_save.call_args[0]
                assert args[0] == "user123"
                assert args[1].major == "Computer Science"

def test_get_my_profile_success():
    """Test retrieving existing profile for authenticated user."""
    mock_user = {"uid": "user123"}
    mock_profile = {
        "major": "Computer Science",
        "class_year": "Junior",
        "skills": ["Python"],
        "interests": [],
        "coursework": [],
        "experience": []
    }
    
    with patch("app.api.deps.FirebaseService.verify_token", return_value=mock_user):
        with patch("app.api.profile.get_student_profile", return_value=mock_profile):
            response = client.get(
                "/api/profile/me",
                headers={"Authorization": "Bearer fake_token"}
            )
            assert response.status_code == 200
            assert response.json()["major"] == "Computer Science"

def test_get_my_profile_not_found():
    """Test retrieving profile when it does not exist."""
    mock_user = {"uid": "user123"}
    
    with patch("app.api.deps.FirebaseService.verify_token", return_value=mock_user):
        with patch("app.api.profile.get_student_profile", return_value=None):
            response = client.get(
                "/api/profile/me",
                headers={"Authorization": "Bearer fake_token"}
            )
            assert response.status_code == 404
