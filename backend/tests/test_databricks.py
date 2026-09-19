"""Tests for GET /test/databricks — all Databricks calls are mocked."""

from unittest.mock import MagicMock, patch

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)

PROVIDER = "databricks"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _make_user(display_name: str) -> MagicMock:
    """Return a mock mimicking the SDK's User object."""
    mock_user = MagicMock()
    mock_user.display_name = display_name
    mock_user.user_name = "test@example.com"
    return mock_user


# ---------------------------------------------------------------------------
# Happy path
# ---------------------------------------------------------------------------


def test_databricks_returns_200_on_success(mocker):
    """A configured profile and successful workspace call → 200 with status ok."""
    mocker.patch(
        "app.services.databricks_service.settings.databricks_config_profile",
        new="test-profile",
    )
    mock_client = MagicMock()
    mock_client.current_user.me.return_value = _make_user("Aiden Okabayashi")

    with patch(
        "app.services.databricks_service.WorkspaceClient",
        return_value=mock_client,
    ):
        response = client.get("/test/databricks")

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    assert body["provider"] == PROVIDER
    assert body["user"] == "Aiden Okabayashi"


def test_databricks_calls_current_user_me(mocker):
    """The service must call current_user.me() to retrieve the authenticated user."""
    mocker.patch(
        "app.services.databricks_service.settings.databricks_config_profile",
        new="test-profile",
    )
    mock_client = MagicMock()
    mock_client.current_user.me.return_value = _make_user("Test User")

    with patch(
        "app.services.databricks_service.WorkspaceClient",
        return_value=mock_client,
    ):
        client.get("/test/databricks")

    mock_client.current_user.me.assert_called_once()


def test_databricks_initialises_client_with_profile(mocker):
    """WorkspaceClient must be initialised with the configured profile name."""
    mocker.patch(
        "app.services.databricks_service.settings.databricks_config_profile",
        new="my-cli-profile",
    )
    mock_client = MagicMock()
    mock_client.current_user.me.return_value = _make_user("Test User")

    with patch(
        "app.services.databricks_service.WorkspaceClient",
        return_value=mock_client,
    ) as mock_ws_cls:
        client.get("/test/databricks")

    mock_ws_cls.assert_called_once_with(profile="my-cli-profile")


# ---------------------------------------------------------------------------
# Missing profile
# ---------------------------------------------------------------------------


def test_databricks_returns_error_when_profile_missing(mocker):
    """Missing DATABRICKS_CONFIG_PROFILE must return status=error, not a 500."""
    mocker.patch(
        "app.services.databricks_service.settings.databricks_config_profile",
        new=None,
    )

    response = client.get("/test/databricks")

    assert response.status_code == 200  # structured error, not HTTP 500
    body = response.json()
    assert body["status"] == "error"
    assert body["provider"] == PROVIDER
    assert "DATABRICKS_CONFIG_PROFILE" in body["user"]


# ---------------------------------------------------------------------------
# Provider failure
# ---------------------------------------------------------------------------


def test_databricks_returns_error_on_provider_failure(mocker):
    """A transient workspace failure must return status=error, not a 500."""
    mocker.patch(
        "app.services.databricks_service.settings.databricks_config_profile",
        new="test-profile",
    )
    mock_client = MagicMock()
    mock_client.current_user.me.side_effect = RuntimeError("connection timeout")

    with patch(
        "app.services.databricks_service.WorkspaceClient",
        return_value=mock_client,
    ):
        response = client.get("/test/databricks")

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "error"
    assert body["provider"] == PROVIDER
    # Raw exception detail must NOT leak into the response
    assert "connection timeout" not in body["user"]

