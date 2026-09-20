"""Unit tests for the Echelon Conversational Agent orchestrator and API endpoint."""

from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.models.opportunity import CareerTrackAffinity
from app.models.recommendation import CareerPreferences
from app.models.student import StudentProfile
from app.services.echelon_agent_service import (
    AgentChatRequest,
    AgentChatResponse,
    AgentServiceError,
    handle_chat,
)
from app.services.gemini_service import AgentUpdate

client = TestClient(app)


def _make_sample_profile() -> StudentProfile:
    return StudentProfile(
        major="Computer Science",
        class_year="Junior",
        skills=["Python"],
        interests=["Cloud"],
    )


class TestAgentService:
    def test_handle_chat_success_without_preference_update(self):
        profile = _make_sample_profile()
        prefs = CareerPreferences()
        mock_agent_update = AgentUpdate(
            assistant_reply="Hello! What kind of software engineering roles are you looking for?",
            updated_preferences=None,
        )

        with (
            patch("app.services.databricks_service.get_student_profile", return_value=profile),
            patch("app.services.databricks_service.get_career_preferences", return_value=prefs),
            patch("app.services.gemini_service.chat_agent", return_value=mock_agent_update),
            patch("app.services.databricks_service.save_career_preferences") as mock_save_prefs,
        ):
            resp = handle_chat("user-123", "Hi, I am looking for summer internships.")

        assert isinstance(resp, AgentChatResponse)
        assert resp.reply == mock_agent_update.assistant_reply
        assert resp.preferences_updated is False
        mock_save_prefs.assert_not_called()

    def test_handle_chat_success_with_preference_update(self):
        profile = _make_sample_profile()
        prefs = CareerPreferences()
        new_prefs = CareerPreferences(
            career_tracks=[CareerTrackAffinity(track="cloud_infrastructure", weight=0.9)],
            preferred_locations=["Northern Virginia"],
        )
        mock_agent_update = AgentUpdate(
            assistant_reply="Got it! I added cloud infrastructure and NoVA to your preferences.",
            updated_preferences=new_prefs,
        )

        with (
            patch("app.services.databricks_service.get_student_profile", return_value=profile),
            patch("app.services.databricks_service.get_career_preferences", return_value=prefs),
            patch("app.services.gemini_service.chat_agent", return_value=mock_agent_update),
            patch("app.services.databricks_service.save_career_preferences") as mock_save_prefs,
        ):
            resp = handle_chat("user-123", "I want cloud infrastructure jobs in Northern Virginia.")

        assert isinstance(resp, AgentChatResponse)
        assert resp.reply == mock_agent_update.assistant_reply
        assert resp.preferences_updated is True
        mock_save_prefs.assert_called_once_with("user-123", new_prefs)

    def test_handle_chat_missing_profile_raises_service_error(self):
        with patch("app.services.databricks_service.get_student_profile", return_value=None):
            with pytest.raises(AgentServiceError) as exc:
                handle_chat("user-unknown", "Hello")

        assert "Student profile not found" in str(exc.value)

    def test_handle_chat_missing_preferences_initializes_default(self):
        profile = _make_sample_profile()
        mock_agent_update = AgentUpdate(
            assistant_reply="Welcome to Echelon!",
            updated_preferences=None,
        )

        with (
            patch("app.services.databricks_service.get_student_profile", return_value=profile),
            patch("app.services.databricks_service.get_career_preferences", return_value=None),
            patch("app.services.gemini_service.chat_agent", return_value=mock_agent_update) as mock_chat,
        ):
            resp = handle_chat("user-123", "Hello")

        assert resp.preferences_updated is False
        mock_chat.assert_called_once()
        args = mock_chat.call_args[0]
        assert isinstance(args[1], CareerPreferences)


class TestAgentRoute:
    def test_chat_route_requires_auth(self):
        response = client.post(
            "/api/agent/chat",
            json={"message": "Looking for backend roles."},
        )
        assert response.status_code in (401, 403)

    def test_chat_route_success(self):
        mock_user = {"uid": "user-456"}
        mock_chat_response = AgentChatResponse(
            reply="I found several great systems roles for you at Virginia Tech.",
            preferences_updated=True,
        )

        with (
            patch("app.api.deps.FirebaseService.verify_token", return_value=mock_user),
            patch("app.api.agent.handle_chat", return_value=mock_chat_response) as mock_handle,
        ):
            response = client.post(
                "/api/agent/chat",
                headers={"Authorization": "Bearer fake_token"},
                json={"message": "What opportunities match my profile?"},
            )

        assert response.status_code == 200
        data = response.json()
        assert data["reply"] == mock_chat_response.reply
        assert data["preferences_updated"] is True
        mock_handle.assert_called_once_with("user-456", "What opportunities match my profile?")

    def test_chat_route_service_error_returns_400(self):
        mock_user = {"uid": "user-456"}

        with (
            patch("app.api.deps.FirebaseService.verify_token", return_value=mock_user),
            patch(
                "app.api.agent.handle_chat",
                side_effect=AgentServiceError("Student profile not found. Please complete onboarding first."),
            ),
        ):
            response = client.post(
                "/api/agent/chat",
                headers={"Authorization": "Bearer fake_token"},
                json={"message": "Hello"},
            )

        assert response.status_code == 400
        assert "complete onboarding first" in response.json()["detail"]

    def test_chat_route_unexpected_error_returns_500(self):
        mock_user = {"uid": "user-456"}

        with (
            patch("app.api.deps.FirebaseService.verify_token", return_value=mock_user),
            patch("app.api.agent.handle_chat", side_effect=RuntimeError("Unexpected crash")),
        ):
            response = client.post(
                "/api/agent/chat",
                headers={"Authorization": "Bearer fake_token"},
                json={"message": "Hello"},
            )

        assert response.status_code == 500
        assert "Internal Server Error" in response.json()["detail"]
        assert "Unexpected crash" not in response.json()["detail"]

    def test_chat_route_missing_uid_returns_401(self):
        """Chat route rejects token that has no uid."""
        with patch("app.api.deps.FirebaseService.verify_token", return_value={"email": "nouid@vt.edu"}):
            response = client.post(
                "/api/agent/chat",
                headers={"Authorization": "Bearer fake_token"},
                json={"message": "Hello"},
            )
        assert response.status_code == 401

    def test_chat_route_provider_error_returns_sanitized_500(self):
        """Chat route returns sanitized 500 when Databricks or Gemini raises."""
        from app.services.databricks_service import DatabricksServiceError

        mock_user = {"uid": "user-456"}
        with (
            patch("app.api.deps.FirebaseService.verify_token", return_value=mock_user),
            patch("app.api.agent.handle_chat", side_effect=DatabricksServiceError("Databricks secret timeout")),
        ):
            response = client.post(
                "/api/agent/chat",
                headers={"Authorization": "Bearer fake_token"},
                json={"message": "Hello"},
            )
        assert response.status_code == 500
        assert "Failed to process chat request." in response.json()["detail"]
        assert "Databricks secret timeout" not in response.json()["detail"]
