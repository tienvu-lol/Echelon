"""Tests for Databricks opportunity persistence.

All Databricks SDK calls are mocked — no live workspace calls.
Tests are organized by concern:

Section 1 – opportunities table DDL compatibility
Section 2 – save_opportunity() upsert behavior and timestamps
Section 3 – get_opportunity() deserialization
Section 4 – list_opportunities() deserialization
Section 5 – save_opportunities() batch helper
Section 6 – Databricks execution failure propagation
Section 7 – setup_tables() creates both tables (regression guard)
"""

import json
from unittest.mock import MagicMock, call, patch

import pytest

from datetime import datetime, timezone

from app.models.opportunity import CareerTrackAffinity, Opportunity
from app.services.databricks_service import (
    DatabricksServiceError,
    _execute_statement,
    get_active_opportunities,
    get_opportunity,
    list_opportunities,
    save_opportunities,
    save_opportunity,
    setup_tables,
)


# ===========================================================================
# Helpers
# ===========================================================================


def _make_opportunity(**overrides) -> Opportunity:
    """Return a minimal valid Opportunity, optionally with field overrides."""
    defaults = dict(
        id="opp-001",
        title="Research Assistant",
        organization="VT CS Department",
        opportunity_type="research",
        description="Work on ML research.",
        source_url="https://cs.vt.edu/opp/001",
    )
    return Opportunity(**{**defaults, **overrides})


def _make_statement_response(
    state_value: str = "SUCCEEDED",
    error_message: str | None = None,
    rows: list | None = None,
    total_row_count: int | None = None,
) -> MagicMock:
    """Build a mock StatementResponse."""
    from databricks.sdk.service.sql import StatementState

    mock_response = MagicMock()

    # status
    mock_status = MagicMock()
    mock_status.state = StatementState(state_value)
    if error_message is not None:
        mock_error = MagicMock()
        mock_error.message = error_message
        mock_status.error = mock_error
    else:
        mock_status.error = None
    mock_response.status = mock_status

    # manifest / result
    actual_rows = rows or []
    actual_count = total_row_count if total_row_count is not None else len(actual_rows)

    mock_manifest = MagicMock()
    mock_manifest.total_row_count = actual_count
    mock_response.manifest = mock_manifest

    mock_result = MagicMock()
    mock_result.data_array = actual_rows if actual_rows else None
    mock_response.result = mock_result

    return mock_response


def _patch_settings(mocker, *, profile: str = "test-profile", warehouse: str = "wh-001"):
    mocker.patch("app.services.databricks_service.settings.databricks_config_profile", new=profile)
    mocker.patch("app.services.databricks_service.settings.databricks_warehouse_id", new=warehouse)
    mocker.patch("app.services.databricks_service.settings.databricks_catalog", new="workspace")
    mocker.patch("app.services.databricks_service.settings.databricks_schema", new="default")


def _make_opp_row(opp: Opportunity) -> list:
    """Serialize an Opportunity as a Databricks result row (same column order as SELECT)."""
    return [
        opp.id,
        opp.title,
        opp.organization,
        opp.opportunity_type,
        opp.description,
        opp.source_url,
        opp.source_name,
        opp.source_age or "",
        opp.active,
        opp.first_seen_at.isoformat() if opp.first_seen_at else "",
        opp.last_seen_at.isoformat() if opp.last_seen_at else "",
        json.dumps(opp.skills),
        json.dumps(opp.interests),
        json.dumps(opp.eligibility),
        json.dumps(opp.majors),
        json.dumps(opp.class_years),
        json.dumps(opp.school_restrictions),
        json.dumps(opp.eligibility_notes),
        json.dumps(opp.degree_levels),
        json.dumps(opp.work_authorization_requirements),
        json.dumps([ct.model_dump() for ct in opp.career_tracks]),
        opp.location or "",
        opp.remote_status or "",
        opp.time_commitment or "",
        opp.compensation or "",
        opp.deadline or "",
        opp.apply_url or "",
        opp.contact_name or "",
        opp.contact_email or "",
    ]


# ===========================================================================
# Section 1 – opportunities table DDL compatibility
# ===========================================================================


class TestOpportunitiesTableDDL:
    """Verify the opportunities DDL is compatible with our live environment."""

    def _run_setup(self, mocker) -> list[str]:
        """Run setup_tables() and return every SQL statement executed."""
        _patch_settings(mocker)
        mock_client = MagicMock()
        mock_client.statement_execution.execute_statement.return_value = (
            _make_statement_response("SUCCEEDED")
        )

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            setup_tables()

        return [
            c.kwargs["statement"]
            for c in mock_client.statement_execution.execute_statement.call_args_list
        ]

    def _opportunities_ddl(self, mocker) -> str:
        stmts = self._run_setup(mocker)
        # The second statement is the opportunities DDL
        assert len(stmts) == 2, "setup_tables() must execute exactly 2 statements"
        return stmts[1]

    def test_creates_exactly_two_tables(self, mocker):
        stmts = self._run_setup(mocker)
        assert len(stmts) == 2

    def test_uses_delta_storage(self, mocker):
        assert "USING DELTA" in self._opportunities_ddl(mocker)

    def test_no_column_default_timestamps(self, mocker):
        assert "DEFAULT CURRENT_TIMESTAMP" not in self._opportunities_ddl(mocker)

    def test_no_primary_key(self, mocker):
        assert "PRIMARY KEY" not in self._opportunities_ddl(mocker)

    def test_create_table_if_not_exists(self, mocker):
        assert "CREATE TABLE IF NOT EXISTS" in self._opportunities_ddl(mocker)

    def test_contains_all_required_columns(self, mocker):
        ddl = self._opportunities_ddl(mocker)
        required = [
            "id", "title", "organization", "opportunity_type",
            "description", "source_url",
        ]
        for col in required:
            assert col in ddl, f"DDL missing required column: {col}"

    def test_contains_all_list_columns(self, mocker):
        ddl = self._opportunities_ddl(mocker)
        for col in ["skills", "interests", "eligibility", "majors", "class_years"]:
            assert col in ddl
            assert "ARRAY<STRING>" in ddl

    def test_contains_timestamp_columns(self, mocker):
        ddl = self._opportunities_ddl(mocker)
        assert "created_at" in ddl
        assert "updated_at" in ddl
        assert "TIMESTAMP" in ddl

    def test_student_profiles_ddl_unchanged(self, mocker):
        """Regression: student_profiles DDL must still be live-compatible."""
        student_ddl = self._run_setup(mocker)[0]
        assert "student_profiles" in student_ddl
        assert "USING DELTA" in student_ddl
        assert "DEFAULT CURRENT_TIMESTAMP" not in student_ddl
        assert "PRIMARY KEY" not in student_ddl


# ===========================================================================
# Section 2 – save_opportunity() upsert behavior and timestamps
# ===========================================================================


class TestSaveOpportunity:

    def _run_save(self, mocker, opp: Opportunity | None = None) -> tuple[str, list]:
        """Run save_opportunity() and return (sql, parameters)."""
        _patch_settings(mocker)
        mock_client = MagicMock()
        mock_client.statement_execution.execute_statement.return_value = (
            _make_statement_response("SUCCEEDED")
        )

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            save_opportunity(opp or _make_opportunity())

        kwargs = mock_client.statement_execution.execute_statement.call_args.kwargs
        return kwargs["statement"], kwargs["parameters"]

    def test_issues_merge_statement(self, mocker):
        sql, _ = self._run_save(mocker)
        assert "MERGE INTO opportunities" in sql

    def test_merge_key_is_opportunity_id(self, mocker):
        sql, _ = self._run_save(mocker)
        assert "ON t.id = s.id" in sql

    def test_insert_sets_created_at(self, mocker):
        sql, _ = self._run_save(mocker)
        # created_at must appear only in the WHEN NOT MATCHED branch
        insert_branch = sql.split("WHEN NOT MATCHED")[1]
        assert "created_at" in insert_branch
        assert "CURRENT_TIMESTAMP()" in insert_branch

    def test_insert_sets_updated_at(self, mocker):
        sql, _ = self._run_save(mocker)
        insert_branch = sql.split("WHEN NOT MATCHED")[1]
        assert "updated_at" in insert_branch

    def test_update_does_not_overwrite_created_at(self, mocker):
        sql, _ = self._run_save(mocker)
        update_branch = sql.split("WHEN NOT MATCHED")[0]
        assert "created_at" not in update_branch

    def test_update_refreshes_updated_at(self, mocker):
        sql, _ = self._run_save(mocker)
        update_branch = sql.split("WHEN NOT MATCHED")[0]
        assert "updated_at" in update_branch
        assert "CURRENT_TIMESTAMP()" in update_branch

    def test_required_fields_are_parameterized(self, mocker):
        opp = _make_opportunity(
            id="opp-xyz",
            title="ML Researcher",
            organization="VT ECE",
            opportunity_type="research",
            description="Great project",
            source_url="https://ece.vt.edu/jobs/1",
        )
        _, params = self._run_save(mocker, opp)
        param_map = {p.name: p.value for p in params}
        assert param_map["id"] == "opp-xyz"
        assert param_map["title"] == "ML Researcher"
        assert param_map["organization"] == "VT ECE"
        assert param_map["source_url"] == "https://ece.vt.edu/jobs/1"

    def test_list_fields_are_json_encoded(self, mocker):
        opp = _make_opportunity(
            skills=["Python", "SQL"],
            interests=["ML", "Data"],
            eligibility=["Undergraduate"],
            majors=["CS", "ECE"],
            class_years=["Junior", "Senior"],
        )
        _, params = self._run_save(mocker, opp)
        param_map = {p.name: p.value for p in params}
        assert json.loads(param_map["skills"]) == ["Python", "SQL"]
        assert json.loads(param_map["interests"]) == ["ML", "Data"]
        assert json.loads(param_map["eligibility"]) == ["Undergraduate"]
        assert json.loads(param_map["majors"]) == ["CS", "ECE"]
        assert json.loads(param_map["class_years"]) == ["Junior", "Senior"]

    def test_empty_lists_encode_as_empty_json_array(self, mocker):
        _, params = self._run_save(mocker, _make_opportunity())
        param_map = {p.name: p.value for p in params}
        assert json.loads(param_map["skills"]) == []
        assert json.loads(param_map["interests"]) == []

    def test_failed_save_raises_service_error(self, mocker):
        _patch_settings(mocker)
        mock_client = MagicMock()
        mock_client.statement_execution.execute_statement.return_value = (
            _make_statement_response("FAILED", error_message="merge conflict")
        )

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            with pytest.raises(DatabricksServiceError):
                save_opportunity(_make_opportunity())


# ===========================================================================
# Section 3 – get_opportunity() deserialization
# ===========================================================================


class TestGetOpportunity:

    def _mock_and_get(self, mocker, opp: Opportunity | None = None) -> Opportunity | None:
        target = opp or _make_opportunity(
            skills=["Python"],
            interests=["AI"],
            location="Blacksburg, VA",
        )
        _patch_settings(mocker)
        mock_client = MagicMock()
        mock_client.statement_execution.execute_statement.return_value = (
            _make_statement_response("SUCCEEDED", rows=[_make_opp_row(target)], total_row_count=1)
        )

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            return get_opportunity(target.id)

    def test_returns_opportunity_on_match(self, mocker):
        result = self._mock_and_get(mocker)
        assert result is not None
        assert isinstance(result, Opportunity)

    def test_required_fields_round_trip(self, mocker):
        opp = _make_opportunity(id="opp-rr", title="Test Role", source_url="https://vt.edu/x")
        result = self._mock_and_get(mocker, opp)
        assert result.id == "opp-rr"
        assert result.title == "Test Role"
        assert result.source_url == "https://vt.edu/x"

    def test_list_fields_deserialize_correctly(self, mocker):
        opp = _make_opportunity(
            skills=["Python", "Spark"],
            interests=["MLops"],
            majors=["CS"],
            class_years=["Senior"],
        )
        result = self._mock_and_get(mocker, opp)
        assert result.skills == ["Python", "Spark"]
        assert result.interests == ["MLops"]
        assert result.majors == ["CS"]
        assert result.class_years == ["Senior"]

    def test_optional_scalar_fields_round_trip(self, mocker):
        opp = _make_opportunity(
            location="Blacksburg, VA",
            deadline="2026-12-01",
            apply_url="https://vt.edu/apply",
        )
        result = self._mock_and_get(mocker, opp)
        assert result.location == "Blacksburg, VA"
        assert result.deadline == "2026-12-01"
        assert result.apply_url == "https://vt.edu/apply"

    def test_returns_none_when_not_found(self, mocker):
        _patch_settings(mocker)
        mock_client = MagicMock()
        mock_client.statement_execution.execute_statement.return_value = (
            _make_statement_response("SUCCEEDED", rows=[], total_row_count=0)
        )

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            result = get_opportunity("nonexistent-id")

        assert result is None

    def test_queries_by_id_parameter(self, mocker):
        _patch_settings(mocker)
        mock_client = MagicMock()
        mock_client.statement_execution.execute_statement.return_value = (
            _make_statement_response("SUCCEEDED", rows=[], total_row_count=0)
        )

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            get_opportunity("target-id")

        params = mock_client.statement_execution.execute_statement.call_args.kwargs["parameters"]
        param_map = {p.name: p.value for p in params}
        assert param_map["id"] == "target-id"

    def test_failed_query_raises_service_error(self, mocker):
        _patch_settings(mocker)
        mock_client = MagicMock()
        mock_client.statement_execution.execute_statement.return_value = (
            _make_statement_response("FAILED")
        )

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            with pytest.raises(DatabricksServiceError):
                get_opportunity("opp-001")


# ===========================================================================
# Section 4 – list_opportunities() deserialization
# ===========================================================================


class TestListOpportunities:

    def test_returns_empty_list_when_no_rows(self, mocker):
        _patch_settings(mocker)
        mock_client = MagicMock()
        mock_client.statement_execution.execute_statement.return_value = (
            _make_statement_response("SUCCEEDED", rows=[], total_row_count=0)
        )

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            result = list_opportunities()

        assert result == []

    def test_returns_multiple_opportunities(self, mocker):
        opps = [
            _make_opportunity(id="opp-a", title="Role A", skills=["Python"]),
            _make_opportunity(id="opp-b", title="Role B", skills=["Java"]),
            _make_opportunity(id="opp-c", title="Role C"),
        ]
        rows = [_make_opp_row(o) for o in opps]

        _patch_settings(mocker)
        mock_client = MagicMock()
        mock_client.statement_execution.execute_statement.return_value = (
            _make_statement_response("SUCCEEDED", rows=rows, total_row_count=len(rows))
        )

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            result = list_opportunities()

        assert len(result) == 3
        assert all(isinstance(r, Opportunity) for r in result)
        ids = [r.id for r in result]
        assert "opp-a" in ids
        assert "opp-b" in ids
        assert "opp-c" in ids

    def test_list_fields_deserialize_for_each_row(self, mocker):
        opps = [
            _make_opportunity(id="opp-1", skills=["Python", "SQL"]),
            _make_opportunity(id="opp-2", skills=["Java"]),
        ]
        rows = [_make_opp_row(o) for o in opps]

        _patch_settings(mocker)
        mock_client = MagicMock()
        mock_client.statement_execution.execute_statement.return_value = (
            _make_statement_response("SUCCEEDED", rows=rows, total_row_count=2)
        )

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            result = list_opportunities()

        result_map = {r.id: r for r in result}
        assert result_map["opp-1"].skills == ["Python", "SQL"]
        assert result_map["opp-2"].skills == ["Java"]

    def test_passes_limit_parameter(self, mocker):
        _patch_settings(mocker)
        mock_client = MagicMock()
        mock_client.statement_execution.execute_statement.return_value = (
            _make_statement_response("SUCCEEDED", rows=[], total_row_count=0)
        )

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            list_opportunities(limit=25)

        params = mock_client.statement_execution.execute_statement.call_args.kwargs["parameters"]
        param_map = {p.name: p.value for p in params}
        assert param_map["lim"] == "25"

    def test_failed_query_raises_service_error(self, mocker):
        _patch_settings(mocker)
        mock_client = MagicMock()
        mock_client.statement_execution.execute_statement.return_value = (
            _make_statement_response("FAILED")
        )

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            with pytest.raises(DatabricksServiceError):
                list_opportunities()


# ===========================================================================
# Section 5 – save_opportunities() batch helper
# ===========================================================================


class TestSaveOpportunities:

    def test_calls_save_for_each_opportunity(self, mocker):
        opps = [_make_opportunity(id=f"opp-{i}") for i in range(3)]

        mock_save = mocker.patch("app.services.databricks_service.save_opportunity")
        save_opportunities(opps)

        assert mock_save.call_count == 3
        saved_ids = [c.args[0].id for c in mock_save.call_args_list]
        assert saved_ids == ["opp-0", "opp-1", "opp-2"]

    def test_empty_list_is_no_op(self, mocker):
        mock_save = mocker.patch("app.services.databricks_service.save_opportunity")
        save_opportunities([])
        mock_save.assert_not_called()


# ===========================================================================
# Section 6 – Execution failure propagation
# ===========================================================================


class TestOpportunityExecutionFailures:

    def test_save_surfaces_failed_state(self, mocker):
        _patch_settings(mocker)
        mock_client = MagicMock()
        mock_client.statement_execution.execute_statement.return_value = (
            _make_statement_response("FAILED", error_message="table not found")
        )

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            with pytest.raises(DatabricksServiceError) as exc_info:
                save_opportunity(_make_opportunity())

        assert "FAILED" in str(exc_info.value)
        assert "table not found" not in str(exc_info.value)  # raw detail must not leak

    def test_get_surfaces_failed_state(self, mocker):
        _patch_settings(mocker)
        mock_client = MagicMock()
        mock_client.statement_execution.execute_statement.return_value = (
            _make_statement_response("CANCELED")
        )

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            with pytest.raises(DatabricksServiceError):
                get_opportunity("opp-001")

    def test_list_surfaces_failed_state(self, mocker):
        _patch_settings(mocker)
        mock_client = MagicMock()
        mock_client.statement_execution.execute_statement.return_value = (
            _make_statement_response("FAILED")
        )

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            with pytest.raises(DatabricksServiceError):
                list_opportunities()


# ===========================================================================
# Section 7 – setup_tables() regression guard (both tables created)
# ===========================================================================


class TestSetupTablesRegression:

    def test_setup_tables_creates_student_profiles_and_opportunities(self, mocker):
        _patch_settings(mocker)
        mock_client = MagicMock()
        mock_client.statement_execution.execute_statement.return_value = (
            _make_statement_response("SUCCEEDED")
        )

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            setup_tables()

        stmts = [
            c.kwargs["statement"]
            for c in mock_client.statement_execution.execute_statement.call_args_list
        ]
        assert any("student_profiles" in s for s in stmts), "student_profiles DDL missing"
        assert any("opportunities" in s for s in stmts), "opportunities DDL missing"

    def test_student_profiles_ddl_still_has_required_columns(self, mocker):
        _patch_settings(mocker)
        mock_client = MagicMock()
        mock_client.statement_execution.execute_statement.return_value = (
            _make_statement_response("SUCCEEDED")
        )

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            setup_tables()

        student_ddl = mock_client.statement_execution.execute_statement.call_args_list[0].kwargs["statement"]
        for col in ["firebase_uid", "skills", "interests", "coursework", "experience"]:
            assert col in student_ddl


# ===========================================================================
# Section 8 – Extended fields round trip and deserialization correctness
# ===========================================================================


class TestOpportunityExtendedFieldsRoundTrip:
    """Verify that extended fields survive Databricks round trips and deserialize accurately."""

    def _make_comprehensive_opportunity(self) -> Opportunity:
        return Opportunity(
            id="opp-ext-001",
            title="Senior Distributed Systems Researcher",
            organization="Virginia Tech National Security Institute",
            opportunity_type="research",
            description="Lead autonomous systems and edge networking research.",
            source_url="https://nsi.vt.edu/opportunities/opp-ext-001",
            source_name="VT NSI Portal",
            source_age="1 week ago",
            active=True,
            first_seen_at=datetime(2026, 9, 1, 12, 0, 0, tzinfo=timezone.utc),
            last_seen_at=datetime(2026, 9, 15, 18, 30, 0, tzinfo=timezone.utc),
            skills=["Rust", "Kubernetes", "C++", "eBPF"],
            interests=["Distributed Systems", "Cloud Security", "Operating Systems"],
            eligibility=["Undergraduate", "Graduate"],
            majors=["Computer Science", "Computer Engineering"],
            class_years=["Junior", "Senior", "Master's"],
            school_restrictions=["College of Engineering"],
            eligibility_notes=["Must have completed CS 3214 Computer Systems."],
            degree_levels=["BS", "MS"],
            work_authorization_requirements=["US Citizen"],
            career_tracks=[
                CareerTrackAffinity(track="cloud_infrastructure", weight=0.95),
                CareerTrackAffinity(track="software_engineering", weight=0.85),
            ],
            location="Blacksburg, VA",
            remote_status="hybrid",
            time_commitment="15 hours/week",
            compensation="$25/hour",
            deadline="2026-11-30",
            apply_url="https://nsi.vt.edu/apply/opp-ext-001",
            contact_name="Dr. Jane Doe",
            contact_email="janedoe@vt.edu",
        )

    def test_save_opportunity_persists_all_extended_parameters(self, mocker):
        """save_opportunity() accurately parameterizes every extended field."""
        opp = self._make_comprehensive_opportunity()
        _patch_settings(mocker)
        mock_client = MagicMock()
        mock_client.statement_execution.execute_statement.return_value = (
            _make_statement_response("SUCCEEDED")
        )

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            save_opportunity(opp)

        params = mock_client.statement_execution.execute_statement.call_args.kwargs["parameters"]
        param_map = {p.name: p.value for p in params}

        assert param_map["source_name"] == "VT NSI Portal"
        assert param_map["source_age"] == "1 week ago"
        assert param_map["active"] == "true"
        assert "2026-09-01T12:00:00" in param_map["first_seen_at"]
        assert "2026-09-15T18:30:00" in param_map["last_seen_at"]
        assert json.loads(param_map["school_restrictions"]) == ["College of Engineering"]
        assert json.loads(param_map["eligibility_notes"]) == ["Must have completed CS 3214 Computer Systems."]
        assert json.loads(param_map["degree_levels"]) == ["BS", "MS"]
        assert json.loads(param_map["work_authorization_requirements"]) == ["US Citizen"]
        assert param_map["remote_status"] == "hybrid"

        tracks_data = json.loads(param_map["career_tracks"])
        assert len(tracks_data) == 2
        assert tracks_data[0]["track"] == "cloud_infrastructure"
        assert tracks_data[0]["weight"] == 0.95

    def test_get_opportunity_deserializes_all_extended_fields_positional(self, mocker):
        """get_opportunity() deserializes all 29 fields when schema manifest is omitted."""
        opp = self._make_comprehensive_opportunity()
        row = _make_opp_row(opp)

        _patch_settings(mocker)
        mock_client = MagicMock()
        mock_client.statement_execution.execute_statement.return_value = (
            _make_statement_response("SUCCEEDED", rows=[row], total_row_count=1)
        )

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            retrieved = get_opportunity(opp.id)

        assert retrieved is not None
        assert retrieved.id == opp.id
        assert retrieved.source_name == "VT NSI Portal"
        assert retrieved.source_age == "1 week ago"
        assert retrieved.active is True
        assert retrieved.first_seen_at is not None
        assert retrieved.last_seen_at is not None
        assert retrieved.school_restrictions == ["College of Engineering"]
        assert retrieved.eligibility_notes == ["Must have completed CS 3214 Computer Systems."]
        assert retrieved.degree_levels == ["BS", "MS"]
        assert retrieved.work_authorization_requirements == ["US Citizen"]
        assert retrieved.remote_status == "hybrid"
        assert len(retrieved.career_tracks) == 2
        assert retrieved.career_tracks[0].track == "cloud_infrastructure"
        assert retrieved.career_tracks[0].weight == 0.95

    def test_get_opportunity_deserializes_with_schema_manifest(self, mocker):
        """get_opportunity() properly maps columns when schema columns manifest is present."""
        from app.services.databricks_service import _OPP_SELECT_COLS

        opp = self._make_comprehensive_opportunity()
        # Row data is out of order, but manifest matches it
        row = [
            "Desc", opp.id, "VT CS", "Legacy Role", "internship", "https://vt.edu",
            "VT", "14", True, "2024-01-01T00:00:00Z", "2024-01-02T00:00:00Z",
            json.dumps(["Python"]), json.dumps(["AI"]), json.dumps(["Junior"]),
            json.dumps(["CS"]), json.dumps(["2027"]),
            "Blacksburg, VA", "10 hrs", "$15/hr", "2026-10-01",
            "https://apply.vt.edu", "Contact", "contact@vt.edu",
            json.dumps(["VT"]), json.dumps(["Must be VT"]), json.dumps(["Bachelors"]),
            json.dumps(["US Citizen"]), json.dumps(["SWE"]), "hybrid"
        ]

        # Construct a schema mapping that matches the out-of-order row
        manifest_cols = [
            MagicMock(name="description"), MagicMock(name="id"), MagicMock(name="organization"),
            MagicMock(name="title"), MagicMock(name="opportunity_type"), MagicMock(name="source_url"),
            MagicMock(name="source_name"), MagicMock(name="source_age"), MagicMock(name="active"),
            MagicMock(name="first_seen_at"), MagicMock(name="last_seen_at"),
            MagicMock(name="skills"), MagicMock(name="interests"), MagicMock(name="experience_level"),
            MagicMock(name="majors"), MagicMock(name="grad_year_expected"),
            MagicMock(name="location"), MagicMock(name="time_commitment"), MagicMock(name="compensation"), MagicMock(name="deadline"),
            MagicMock(name="apply_url"), MagicMock(name="contact_name"), MagicMock(name="contact_email"),
            MagicMock(name="school_restrictions"), MagicMock(name="eligibility_notes"), MagicMock(name="degree_levels"),
            MagicMock(name="work_authorization_requirements"), MagicMock(name="career_tracks"), MagicMock(name="remote_status")
        ]

        manifest_cols[0].name = "description"
        manifest_cols[1].name = "id"
        manifest_cols[2].name = "organization"
        manifest_cols[3].name = "title"
        manifest_cols[4].name = "opportunity_type"
        manifest_cols[5].name = "source_url"
        manifest_cols[6].name = "source_name"
        manifest_cols[7].name = "source_age"
        manifest_cols[8].name = "active"
        manifest_cols[9].name = "first_seen_at"
        manifest_cols[10].name = "last_seen_at"
        manifest_cols[11].name = "skills"
        manifest_cols[12].name = "interests"
        manifest_cols[13].name = "experience_level"
        manifest_cols[14].name = "majors"
        manifest_cols[15].name = "grad_year_expected"
        manifest_cols[16].name = "location"
        manifest_cols[17].name = "time_commitment"
        manifest_cols[18].name = "compensation"
        manifest_cols[19].name = "deadline"
        manifest_cols[20].name = "apply_url"
        manifest_cols[21].name = "contact_name"
        manifest_cols[22].name = "contact_email"
        manifest_cols[23].name = "school_restrictions"
        manifest_cols[24].name = "eligibility_notes"
        manifest_cols[25].name = "degree_levels"
        manifest_cols[26].name = "work_authorization_requirements"
        manifest_cols[27].name = "career_tracks"
        manifest_cols[28].name = "remote_status"

        _patch_settings(mocker)
        mock_client = MagicMock()
        resp = _make_statement_response("SUCCEEDED", rows=[row], total_row_count=1)
        resp.manifest.schema.columns = manifest_cols
        mock_client.statement_execution.execute_statement.return_value = resp

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            retrieved = get_opportunity(opp.id)

        assert retrieved.id == opp.id
        assert retrieved.title == "Legacy Role"
        assert retrieved.description == "Desc"
        assert retrieved.skills == ["Python"]

    def test_get_opportunity_29_column_row_fallback(self, mocker):
        """get_opportunity() supports 29-column mock rows without schema manifest."""
        legacy_row = [
            "opp-legacy", "Legacy Role", "VT CS", "internship", "Desc", "https://vt.edu",
            "VT", "14", True, "2024-01-01T00:00:00Z", "2024-01-02T00:00:00Z",
            json.dumps(["Python"]), json.dumps(["AI"]), json.dumps(["Junior"]),
            json.dumps(["CS"]), json.dumps(["2027"]),
            json.dumps(["VT"]), json.dumps(["Must be VT"]), json.dumps(["Bachelors"]),
            json.dumps(["US Citizen"]), json.dumps(["SWE"]),
            "Blacksburg, VA", "hybrid", "10 hrs", "$15/hr", "2026-10-01",
            "https://apply.vt.edu", "Contact", "contact@vt.edu",
        ]
        assert len(legacy_row) == 29

        _patch_settings(mocker)
        mock_client = MagicMock()
        mock_client.statement_execution.execute_statement.return_value = (
            _make_statement_response("SUCCEEDED", rows=[legacy_row], total_row_count=1)
        )

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            retrieved = get_opportunity("opp-legacy")

        assert retrieved.id == "opp-legacy"
        assert retrieved.title == "Legacy Role"
        assert retrieved.skills == ["Python"]
        assert retrieved.remote_status == "hybrid"

    def test_get_active_opportunities_deserializes_extended_fields(self, mocker):
        """get_active_opportunities() queries canonical columns and deserializes extended fields."""
        opp = self._make_comprehensive_opportunity()
        row = _make_opp_row(opp)

        _patch_settings(mocker)
        mock_client = MagicMock()
        mock_client.statement_execution.execute_statement.return_value = (
            _make_statement_response("SUCCEEDED", rows=[row], total_row_count=1)
        )

        with patch("app.services.databricks_service.WorkspaceClient", return_value=mock_client):
            active_opps = get_active_opportunities()

        assert len(active_opps) == 1
        retrieved = active_opps[0]
        assert retrieved.id == opp.id
        assert retrieved.source_name == "VT NSI Portal"
        assert retrieved.active is True
        assert retrieved.remote_status == "hybrid"
        assert len(retrieved.career_tracks) == 2

        # Verify SQL statement executed
        statement = mock_client.statement_execution.execute_statement.call_args.kwargs["statement"]
        assert "WHERE active = true" in statement
        assert "school_restrictions" in statement
        assert "career_tracks" in statement
