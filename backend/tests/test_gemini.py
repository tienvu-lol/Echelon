"""Tests for GET /test/gemini — all Gemini calls are mocked."""

from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

PROVIDER = "gemini-agent-platform"


def _make_response(text: str) -> MagicMock:
    """Return a mock that mimics google.genai GenerateContentResponse."""
    mock_response = MagicMock()
    mock_response.text = text
    return mock_response


# ---------------------------------------------------------------------------
# Happy path
# ---------------------------------------------------------------------------


def test_gemini_returns_200_on_success(mocker):
    """A valid API key and successful provider call → 200 with status ok."""
    mocker.patch(
        "app.services.gemini_service.settings.google_api_key",
        new=MagicMock(get_secret_value=lambda: "fake-key"),
    )
    mock_client = MagicMock()
    mock_client.models.generate_content.return_value = _make_response("pong")

    with patch("app.services.gemini_service.genai.Client", return_value=mock_client):
        response = client.get("/test/gemini")

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    assert body["provider"] == PROVIDER
    assert body["response"] == "pong"


def test_gemini_passes_correct_model_and_prompt(mocker):
    """The service must call generate_content with the expected model id."""
    mocker.patch(
        "app.services.gemini_service.settings.google_api_key",
        new=MagicMock(get_secret_value=lambda: "fake-key"),
    )
    mock_client = MagicMock()
    mock_client.models.generate_content.return_value = _make_response("pong")

    with patch("app.services.gemini_service.genai.Client", return_value=mock_client):
        client.get("/test/gemini")

    mock_client.models.generate_content.assert_called_once()
    call_kwargs = mock_client.models.generate_content.call_args
    assert call_kwargs.kwargs.get("model") == "gemini-3.5-flash"


# ---------------------------------------------------------------------------
# Missing API key
# ---------------------------------------------------------------------------


def test_gemini_returns_error_when_key_missing(mocker):
    """Missing GOOGLE_API_KEY must return status=error, not raise a 500."""
    mocker.patch(
        "app.services.gemini_service.settings.google_api_key",
        new=None,
    )

    response = client.get("/test/gemini")

    assert response.status_code == 200  # structured error, not HTTP 500
    body = response.json()
    assert body["status"] == "error"
    assert body["provider"] == PROVIDER
    assert "GOOGLE_API_KEY" in body["response"]


# ---------------------------------------------------------------------------
# Provider failure
# ---------------------------------------------------------------------------


def test_gemini_returns_error_on_provider_failure(mocker):
    """A transient Gemini API failure must return status=error, not a 500."""
    mocker.patch(
        "app.services.gemini_service.settings.google_api_key",
        new=MagicMock(get_secret_value=lambda: "fake-key"),
    )
    mock_client = MagicMock()
    mock_client.models.generate_content.side_effect = RuntimeError("network error")

    with patch("app.services.gemini_service.genai.Client", return_value=mock_client):
        response = client.get("/test/gemini")

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "error"
    assert body["provider"] == PROVIDER
    # Raw exception detail ("network error") must NOT appear in the response
    assert "network error" not in body["response"]

