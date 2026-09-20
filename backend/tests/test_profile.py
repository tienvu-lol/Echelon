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


def test_get_my_profile_databricks_error():
    """Test retrieving profile handles DatabricksServiceError with 500."""
    from app.services.databricks_service import DatabricksServiceError

    mock_user = {"uid": "user123"}
    with patch("app.api.deps.FirebaseService.verify_token", return_value=mock_user):
        with patch("app.api.profile.get_student_profile", side_effect=DatabricksServiceError("DB down")):
            response = client.get(
                "/api/profile/me",
                headers={"Authorization": "Bearer fake_token"}
            )
            assert response.status_code == 500
            assert "Failed to retrieve profile" in response.json()["detail"]


def test_parse_profile_rejects_non_pdf():
    """Ensure non-PDF upload returns 400 Bad Request."""
    mock_user = {"uid": "user123"}
    with patch("app.api.deps.FirebaseService.verify_token", return_value=mock_user):
        response = client.post(
            "/api/profile/parse",
            headers={"Authorization": "Bearer fake_token"},
            files={"resume": ("test.docx", b"dummy content", "application/vnd.openxmlformats-officedocument.wordprocessingml.document")},
        )
        assert response.status_code == 400
        assert "PDF file" in response.json()["detail"]


def test_parse_profile_gemini_error():
    """Ensure resume parsing error in Gemini returns sanitized 500 without leaking raw details."""
    from app.services.gemini_service import GeminiServiceError

    mock_user = {"uid": "user123"}
    with patch("app.api.deps.FirebaseService.verify_token", return_value=mock_user):
        with patch("app.api.profile.parse_resume", side_effect=GeminiServiceError("Gemini rate limit")):
            response = client.post(
                "/api/profile/parse",
                headers={"Authorization": "Bearer fake_token"},
                files={"resume": ("test.pdf", b"dummy content", "application/pdf")},
            )
            assert response.status_code == 500
            assert "Failed to parse resume" in response.json()["detail"]
            assert "Gemini rate limit" not in response.json()["detail"]



def test_parse_profile_databricks_save_error():
    """Ensure failure to save parsed profile to Databricks returns 500."""
    from app.models.student import StudentProfile
    from app.services.databricks_service import DatabricksServiceError

    mock_user = {"uid": "user123"}
    mock_parsed = StudentProfile(major="Computer Science", class_year="Junior")

    with patch("app.api.deps.FirebaseService.verify_token", return_value=mock_user):
        with patch("app.api.profile.parse_resume", return_value=mock_parsed):
            with patch("app.api.profile.save_student_profile", side_effect=DatabricksServiceError("DB merge failed")):
                response = client.post(
                    "/api/profile/parse",
                    headers={"Authorization": "Bearer fake_token"},
                    files={"resume": ("test.pdf", b"dummy content", "application/pdf")},
                )
                assert response.status_code == 500
                assert "failed to save to Databricks" in response.json()["detail"]


def test_create_profile_requires_auth():
    """Ensure manual profile creation requires authentication."""
    response = client.post(
        "/api/profile",
        json={"major": "Computer Science", "graduation_year": 2027}
    )
    assert response.status_code in (401, 403)


def test_create_profile_success():
    """Ensure manual profile creation succeeds and maps graduation_year to class_year."""
    mock_user = {"uid": "user123"}
    payload = {
        "major": "Computer Science",
        "graduation_year": 2027,
        "skills": ["Python", "Docker"],
        "interests": ["Cloud", "AI"],
        "coursework": ["Systems"],
        "experience": ["TA"],
        "bio": "CS junior",
    }

    with patch("app.api.deps.FirebaseService.verify_token", return_value=mock_user):
        with patch("app.api.profile.save_student_profile") as mock_save:
            response = client.post(
                "/api/profile",
                headers={"Authorization": "Bearer fake_token"},
                json=payload,
            )
            assert response.status_code == 200
            data = response.json()
            assert data["major"] == "Computer Science"
            assert data["class_year"] == "2027"
            assert "Docker" in data["skills"]
            assert data["bio"] == "CS junior"

            mock_save.assert_called_once()
            saved_uid, saved_profile = mock_save.call_args[0]
            assert saved_uid == "user123"
            assert saved_profile.major == "Computer Science"
            assert saved_profile.class_year == "2027"


def test_create_profile_databricks_error():
    """Ensure manual profile creation handles Databricks error with 500."""
    from app.services.databricks_service import DatabricksServiceError

    mock_user = {"uid": "user123"}
    payload = {"major": "Mechanical Engineering", "graduation_year": 2026}

    with patch("app.api.deps.FirebaseService.verify_token", return_value=mock_user):
        with patch("app.api.profile.save_student_profile", side_effect=DatabricksServiceError("Connection lost")):
            response = client.post(
                "/api/profile",
                headers={"Authorization": "Bearer fake_token"},
                json=payload,
            )
            assert response.status_code == 500
            assert "Failed to save profile" in response.json()["detail"]


def test_get_my_profile_missing_uid_returns_401():
    """Ensure GET /api/profile/me rejects decoded token without uid."""
    with patch("app.api.deps.FirebaseService.verify_token", return_value={"email": "no-uid@vt.edu"}):
        response = client.get(
            "/api/profile/me",
            headers={"Authorization": "Bearer fake_token"},
        )
        assert response.status_code == 401


def test_parse_profile_missing_uid_returns_401():
    """Ensure POST /api/profile/parse rejects decoded token without uid."""
    with patch("app.api.deps.FirebaseService.verify_token", return_value={"email": "no-uid@vt.edu"}):
        response = client.post(
            "/api/profile/parse",
            headers={"Authorization": "Bearer fake_token"},
            files={"resume": ("test.pdf", b"%PDF-dummy", "application/pdf")},
        )
        assert response.status_code == 401


def test_create_profile_missing_uid_returns_401():
    """Ensure POST /api/profile rejects decoded token without uid."""
    with patch("app.api.deps.FirebaseService.verify_token", return_value={"email": "no-uid@vt.edu"}):
        response = client.post(
            "/api/profile",
            headers={"Authorization": "Bearer fake_token"},
            json={"major": "CS", "graduation_year": 2027},
        )
        assert response.status_code == 401
