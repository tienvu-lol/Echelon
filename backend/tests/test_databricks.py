"""Tests for Databricks service layer.

Section 1 – GET /test/databricks endpoint (existing, preserved).
Section 2 – _execute_statement() status detection (bug-fix tests).
Section 3 – save_student_profile() timestamp injection.
Section 4 – setup_tables() DDL compatibility.

All Databricks SDK calls are mocked — no live workspace calls.
"""

import json
from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.models.student import StudentProfile
from app.services.databricks_service import (
    DatabricksServiceError,
    _execute_statement,
    get_student_profile,
    migrate_schema,
    save_student_profile,
    setup_tables,
)


client = TestClient(app)

PROVIDER = "databricks"


# ===========================================================================
# Helpers
# ===========================================================================


def _make_user(display_name: str) -> MagicMock:
    """Return a mock mimicking the SDK's User object."""
    mock_user = MagicMock()
    mock_user.display_name = display_name
    mock_user.user_name = "test@example.com"
    return mock_user


def _make_statement_response(state_value: str, error_message: str | None = None) -> MagicMock:
    """Build a mock StatementResponse with the given terminal state."""
    from databricks.sdk.service.sql import StatementState

    mock_response = MagicMock()

    mock_status = MagicMock()
    mock_status.state = StatementState(state_value)

    if error_message is not None:
        mock_error = MagicMock()
        mock_error.message = error_message
        mock_status.error = mock_error
    else:
        mock_status.error = None

    mock_response.status = mock_status
    return mock_response


def _patch_settings(mocker, *, profile: str = "test-profile", warehouse: str = "wh-001"):
    """Patch the config values _execute_statement() reads."""
    mocker.patch(
        "app.services.databricks_service.settings.databricks_config_profile",
        new=profile,
    )
    mocker.patch(
        "app.services.databricks_service.settings.databricks_warehouse_id",
        new=warehouse,
    )
    mocker.patch(
        "app.services.databricks_service.settings.databricks_catalog",
        new="workspace",
    )
    mocker.patch(
        "app.services.databricks_service.settings.databricks_schema",
        new="default",
    )


# ===========================================================================
# Section 1 – /test/databricks endpoint (preserved)
# ===========================================================================


def test_databricks_returns_200_on_success(mocker):
    """A configured profile and successful workspace call → 200 with status ok."""
    mocker.patch(
        "app.services.databricks_service.settings.databricks_config_profile",
        new="test-profile",
    )
    mock_client = MagicMock()
    mock_client.current_user.me.return_value = _make_user("Aiden Okabayashi")

    with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
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

    with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
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
        "app.services.databricks_service.WorkspaceClient", return_value=mock_client
    ) as mock_ws_cls:
        client.get("/test/databricks")

    mock_ws_cls.assert_called_once_with(profile="my-cli-profile")


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


def test_databricks_returns_error_on_provider_failure(mocker):
    """A transient workspace failure must return status=error, not a 500."""
    mocker.patch(
        "app.services.databricks_service.settings.databricks_config_profile",
        new="test-profile",
    )
    mock_client = MagicMock()
    mock_client.current_user.me.side_effect = RuntimeError("connection timeout")

    with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
        response = client.get("/test/databricks")

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "error"
    assert body["provider"] == PROVIDER
    # Raw exception detail must NOT leak into the response
    assert "connection timeout" not in body["user"]


# ===========================================================================
# Section 2 – _execute_statement() status detection (bug-fix tests)
# ===========================================================================


class TestExecuteStatementStatusDetection:
    """The core bug: SDK returns FAILED without raising — we must detect it."""

    def test_succeeded_state_returns_response(self, mocker):
        """SUCCEEDED → response returned, no exception raised."""
        _patch_settings(mocker)
        mock_client = MagicMock()
        mock_client.statement_execution.execute_statement.return_value = (
            _make_statement_response("SUCCEEDED")
        )

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            result = _execute_statement("SELECT 1")

        assert result is not None
        mock_client.statement_execution.execute_statement.assert_called_once()

    def test_failed_state_raises_service_error(self, mocker):
        """FAILED state → DatabricksServiceError must be raised."""
        _patch_settings(mocker)
        mock_client = MagicMock()
        mock_client.statement_execution.execute_statement.return_value = (
            _make_statement_response("FAILED", error_message="Syntax error near DEFAULT")
        )

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            with pytest.raises(DatabricksServiceError) as exc_info:
                _execute_statement("CREATE TABLE bad ...")

        assert "FAILED" in str(exc_info.value)

    def test_failed_state_does_not_leak_raw_error_message(self, mocker):
        """Raw Databricks error text must NOT appear in the public exception message."""
        _patch_settings(mocker)
        raw_detail = "Internal server error: delta column defaults not enabled"
        mock_client = MagicMock()
        mock_client.statement_execution.execute_statement.return_value = (
            _make_statement_response("FAILED", error_message=raw_detail)
        )

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            with pytest.raises(DatabricksServiceError) as exc_info:
                _execute_statement("CREATE TABLE ...")

        assert raw_detail not in str(exc_info.value)

    def test_canceled_state_raises_service_error(self, mocker):
        """CANCELED state → DatabricksServiceError raised (not silently ignored)."""
        _patch_settings(mocker)
        mock_client = MagicMock()
        mock_client.statement_execution.execute_statement.return_value = (
            _make_statement_response("CANCELED")
        )

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            with pytest.raises(DatabricksServiceError) as exc_info:
                _execute_statement("SELECT 1")

        assert "CANCELED" in str(exc_info.value)

    def test_missing_warehouse_id_raises_before_sdk_call(self, mocker):
        """Missing DATABRICKS_WAREHOUSE_ID must raise before any SDK call."""
        mocker.patch(
            "app.services.databricks_service.settings.databricks_config_profile",
            new="test-profile",
        )
        mocker.patch(
            "app.services.databricks_service.settings.databricks_warehouse_id",
            new=None,
        )
        mock_client = MagicMock()

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            with pytest.raises(DatabricksServiceError) as exc_info:
                _execute_statement("SELECT 1")

        assert "DATABRICKS_WAREHOUSE_ID" in str(exc_info.value)
        mock_client.statement_execution.execute_statement.assert_not_called()

    def test_sdk_exception_is_wrapped(self, mocker):
        """SDK-raised DatabricksError must be wrapped into DatabricksServiceError."""
        from databricks.sdk.errors import DatabricksError as SDKError

        _patch_settings(mocker)
        mock_client = MagicMock()
        mock_client.statement_execution.execute_statement.side_effect = SDKError("auth failure")

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            with pytest.raises(DatabricksServiceError):
                _execute_statement("SELECT 1")

    def test_exception_chain_is_preserved(self, mocker):
        """Internal __cause__ must be set so developers can inspect the root cause."""
        from databricks.sdk.errors import DatabricksError as SDKError

        _patch_settings(mocker)
        original = SDKError("root cause")
        mock_client = MagicMock()
        mock_client.statement_execution.execute_statement.side_effect = original

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            with pytest.raises(DatabricksServiceError) as exc_info:
                _execute_statement("SELECT 1")

        assert exc_info.value.__cause__ is original


# ===========================================================================
# Section 3 – save_student_profile() timestamp injection
# ===========================================================================


class TestSaveStudentProfileTimestamps:
    """INSERT must set both timestamps; UPDATE must only refresh updated_at."""

    def _run_save(self, mocker, *, firebase_uid: str = "uid-123") -> str:
        """Run save_student_profile() with a mocked SUCCEEDED response and return the SQL."""
        _patch_settings(mocker)
        mock_client = MagicMock()
        mock_client.statement_execution.execute_statement.return_value = (
            _make_statement_response("SUCCEEDED")
        )

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            save_student_profile(firebase_uid, StudentProfile())

        return mock_client.statement_execution.execute_statement.call_args.kwargs["statement"]

    def test_insert_sets_created_at(self, mocker):
        sql = self._run_save(mocker)
        assert "created_at" in sql.lower()
        assert "CURRENT_TIMESTAMP()" in sql

    def test_insert_sets_updated_at(self, mocker):
        sql = self._run_save(mocker)
        assert "updated_at" in sql.lower()

    def test_update_does_not_overwrite_created_at(self, mocker):
        """The WHEN MATCHED branch must not touch created_at."""
        sql = self._run_save(mocker)
        # Split on WHEN NOT MATCHED to isolate the UPDATE branch
        update_branch = sql.split("WHEN NOT MATCHED")[0]
        assert "created_at" not in update_branch.lower()

    def test_failed_save_raises_service_error(self, mocker):
        _patch_settings(mocker)
        mock_client = MagicMock()
        mock_client.statement_execution.execute_statement.return_value = (
            _make_statement_response("FAILED", error_message="merge error")
        )

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            with pytest.raises(DatabricksServiceError):
                save_student_profile("uid-123", StudentProfile())


# ===========================================================================
# Section 4 – setup_tables() DDL compatibility
# ===========================================================================


class TestSetupTablesDDL:
    def _run_setup(self, mocker) -> str:
        """Run setup_tables() with a mocked SUCCEEDED response and return the DDL."""
        _patch_settings(mocker)
        mock_client = MagicMock()
        mock_client.statement_execution.execute_statement.return_value = (
            _make_statement_response("SUCCEEDED")
        )

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            setup_tables()

        return mock_client.statement_execution.execute_statement.call_args.kwargs["statement"]

    def test_uses_delta_storage(self, mocker):
        ddl = self._run_setup(mocker)
        assert "USING DELTA" in ddl

    def test_no_default_current_timestamp(self, mocker):
        """Column defaults are not supported — DDL must not include them."""
        ddl = self._run_setup(mocker)
        assert "DEFAULT CURRENT_TIMESTAMP" not in ddl

    def test_no_primary_key_declaration(self, mocker):
        """PRIMARY KEY is not used in the live environment."""
        ddl = self._run_setup(mocker)
        assert "PRIMARY KEY" not in ddl

    def test_create_table_if_not_exists(self, mocker):
        ddl = self._run_setup(mocker)
        assert "CREATE TABLE IF NOT EXISTS" in ddl

    def test_failed_setup_raises_service_error(self, mocker):
        """A failed DDL must raise DatabricksServiceError, not silently pass."""
        _patch_settings(mocker)
        mock_client = MagicMock()
        mock_client.statement_execution.execute_statement.return_value = (
            _make_statement_response(
                "FAILED", error_message="delta column defaults not enabled"
            )
        )

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            with pytest.raises(DatabricksServiceError):
                setup_tables()


class TestMigrateSchema:
    def test_migrate_schema_no_missing_columns(self, mocker):
        """When all columns are already present across all tables, no ALTER TABLE statements are run."""
        _patch_settings(mocker)
        mock_client = MagicMock()

        success_resp = _make_statement_response("SUCCEEDED")

        opp_cols = [
            ["id", "string", ""],
            ["title", "string", ""],
            ["organization", "string", ""],
            ["source_name", "string", ""],
            ["source_age", "string", ""],
            ["active", "boolean", ""],
            ["first_seen_at", "timestamp", ""],
            ["last_seen_at", "timestamp", ""],
            ["school_restrictions", "array<string>", ""],
            ["eligibility_notes", "array<string>", ""],
            ["degree_levels", "array<string>", ""],
            ["work_authorization_requirements", "array<string>", ""],
            ["career_tracks", "string", ""],
            ["remote_status", "string", ""],
        ]
        cp_cols = [
            ["firebase_uid", "string", ""],
            ["career_tracks", "string", ""],
            ["preferred_role_types", "array<string>", ""],
            ["preferred_locations", "array<string>", ""],
            ["remote_preference", "string", ""],
            ["industries_of_interest", "array<string>", ""],
            ["technologies_to_use", "array<string>", ""],
            ["technologies_to_learn", "array<string>", ""],
            ["research_vs_industry", "string", ""],
            ["startup_vs_large_company", "string", ""],
            ["career_goals", "string", ""],
            ["other_preferences", "string", ""],
        ]
        swipes_cols = [
            ["id", "string", ""],
            ["student_id", "string", ""],
            ["opportunity_id", "string", ""],
            ["direction", "string", ""],
            ["created_at", "timestamp", ""],
        ]
        saved_cols = [
            ["student_id", "string", ""],
            ["opportunity_id", "string", ""],
            ["created_at", "timestamp", ""],
        ]

        statements_executed = []

        def fake_execute(statement, **kwargs):
            statements_executed.append(statement)
            if "DESCRIBE TABLE" in statement:
                resp = _make_statement_response("SUCCEEDED")
                if "saved_opportunities" in statement:
                    resp.result.data_array = saved_cols
                elif "opportunities" in statement:
                    resp.result.data_array = opp_cols
                elif "career_preferences" in statement:
                    resp.result.data_array = cp_cols
                elif "swipes" in statement:
                    resp.result.data_array = swipes_cols
                return resp
            return success_resp

        mock_client.statement_execution.execute_statement.side_effect = fake_execute

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            summary = migrate_schema()

        assert summary["columns_added"] == []
        assert any("UPDATE opportunities SET active = true" in s for s in statements_executed)
        assert not any("ALTER TABLE" in s for s in statements_executed)

    def test_migrate_schema_adds_missing_columns(self, mocker):
        """When columns are missing, ALTER TABLE statements are executed."""
        _patch_settings(mocker)
        mock_client = MagicMock()

        desc_resp = _make_statement_response("SUCCEEDED")
        desc_resp.result.data_array = [
            ["id", "string", ""],
            ["title", "string", ""],
            ["organization", "string", ""],
        ]

        statements_executed = []

        def fake_execute(statement, **kwargs):
            statements_executed.append(statement)
            if "DESCRIBE TABLE" in statement:
                return desc_resp
            return _make_statement_response("SUCCEEDED")

        mock_client.statement_execution.execute_statement.side_effect = fake_execute

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            summary = migrate_schema()

        assert "active" in summary["columns_added"]
        assert "source_name" in summary["columns_added"]
        assert "career_tracks" in summary["columns_added"]
        alter_statements = [s for s in statements_executed if "ALTER TABLE opportunities ADD COLUMN" in s]
        assert len(alter_statements) == 11
        assert any("UPDATE opportunities SET active = true" in s for s in statements_executed)

    def test_migrate_schema_upgrades_career_preferences_when_missing(self, mocker):
        """When career_preferences has missing columns, they are added via ALTER TABLE."""
        _patch_settings(mocker)
        mock_client = MagicMock()

        statements_executed = []

        def fake_execute(statement, **kwargs):
            statements_executed.append(statement)
            if "DESCRIBE TABLE" in statement:
                resp = _make_statement_response("SUCCEEDED")
                if "career_preferences" in statement:
                    # Missing career_tracks and other_preferences
                    resp.result.data_array = [["firebase_uid", "string", ""]]
                else:
                    # Other tables full
                    resp.result.data_array = [
                        ["id", "string", ""], ["title", "string", ""], ["organization", "string", ""],
                        ["source_name", "string", ""], ["source_age", "string", ""], ["active", "boolean", ""],
                        ["first_seen_at", "timestamp", ""], ["last_seen_at", "timestamp", ""],
                        ["school_restrictions", "array<string>", ""], ["eligibility_notes", "array<string>", ""],
                        ["degree_levels", "array<string>", ""], ["work_authorization_requirements", "array<string>", ""],
                        ["career_tracks", "string", ""], ["remote_status", "string", ""],
                        ["student_id", "string", ""], ["opportunity_id", "string", ""],
                        ["direction", "string", ""], ["created_at", "timestamp", ""],
                    ]
                return resp
            return _make_statement_response("SUCCEEDED")

        mock_client.statement_execution.execute_statement.side_effect = fake_execute

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            summary = migrate_schema()

        assert "career_preferences.career_tracks" in summary["columns_added"]
        cp_alters = [s for s in statements_executed if "ALTER TABLE career_preferences ADD COLUMN" in s]
        assert len(cp_alters) > 0

    def test_migrate_schema_upgrades_swipes_and_saved_when_missing(self, mocker):
        """When swipes and saved_opportunities are missing columns, they are added via ALTER TABLE."""
        _patch_settings(mocker)
        mock_client = MagicMock()

        statements_executed = []

        def fake_execute(statement, **kwargs):
            statements_executed.append(statement)
            if "DESCRIBE TABLE" in statement:
                resp = _make_statement_response("SUCCEEDED")
                if "swipes" in statement:
                    resp.result.data_array = [["id", "string", ""]]
                elif "saved_opportunities" in statement:
                    resp.result.data_array = [["student_id", "string", ""]]
                else:
                    resp.result.data_array = [
                        ["id", "string", ""], ["title", "string", ""], ["organization", "string", ""],
                        ["source_name", "string", ""], ["source_age", "string", ""], ["active", "boolean", ""],
                        ["first_seen_at", "timestamp", ""], ["last_seen_at", "timestamp", ""],
                        ["school_restrictions", "array<string>", ""], ["eligibility_notes", "array<string>", ""],
                        ["degree_levels", "array<string>", ""], ["work_authorization_requirements", "array<string>", ""],
                        ["career_tracks", "string", ""], ["remote_status", "string", ""],
                        ["firebase_uid", "string", ""], ["preferred_role_types", "array<string>", ""],
                        ["preferred_locations", "array<string>", ""], ["remote_preference", "string", ""],
                        ["industries_of_interest", "array<string>", ""], ["technologies_to_use", "array<string>", ""],
                        ["technologies_to_learn", "array<string>", ""], ["research_vs_industry", "string", ""],
                        ["startup_vs_large_company", "string", ""], ["career_goals", "string", ""],
                        ["other_preferences", "string", ""],
                    ]
                return resp
            return _make_statement_response("SUCCEEDED")

        mock_client.statement_execution.execute_statement.side_effect = fake_execute

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            summary = migrate_schema()

        assert "swipes.student_id" in summary["columns_added"]
        assert "saved_opportunities.opportunity_id" in summary["columns_added"]

    def test_migrate_schema_failure_raises(self, mocker):
        """Failure during ALTER TABLE raises DatabricksServiceError."""
        _patch_settings(mocker)
        mock_client = MagicMock()

        desc_resp = _make_statement_response("SUCCEEDED")
        desc_resp.result.data_array = [["id", "string", ""]]

        def fake_execute(statement, **kwargs):
            if "ALTER TABLE" in statement:
                return _make_statement_response("FAILED", error_message="Permission denied")
            return _make_statement_response("SUCCEEDED")

        mock_client.statement_execution.execute_statement.side_effect = fake_execute

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            with pytest.raises(DatabricksServiceError):
                migrate_schema()
