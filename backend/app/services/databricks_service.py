"""Databricks workspace service.

Wraps the Databricks Python SDK (WorkspaceClient) and exposes entry points
used by route handlers.  All provider-specific logic lives here; routes
stay thin.

The SDK is fully synchronous.  FastAPI runs synchronous route handlers in a
thread-pool executor, so blocking calls here are safe as long as the route
handlers themselves are plain ``def`` (not ``async def``).
"""

import json
import logging
from typing import Optional

from databricks.sdk import WorkspaceClient
from databricks.sdk.errors import DatabricksError
from databricks.sdk.service.sql import (
    StatementParameterListItem,
    StatementResponse,
    StatementState,
)

from app.core.config import settings
from app.models.opportunity import Opportunity
from app.models.student import StudentProfile

logger = logging.getLogger(__name__)


class DatabricksServiceError(Exception):
    """Raised when the Databricks service cannot fulfil a request."""


# ---------------------------------------------------------------------------
# Client factory
# ---------------------------------------------------------------------------


def _get_client() -> WorkspaceClient:
    """Build and return a configured WorkspaceClient.

    Uses unified authentication via the CLI profile stored in
    ``DATABRICKS_CONFIG_PROFILE``.  No PATs or hardcoded credentials.

    Raises:
        DatabricksServiceError: if the profile name is not configured.
    """
    if not settings.databricks_config_profile:
        raise DatabricksServiceError(
            "DATABRICKS_CONFIG_PROFILE is not set. "
            "Add it to your environment or .env file."
        )
    return WorkspaceClient(profile=settings.databricks_config_profile)


# ---------------------------------------------------------------------------
# Workspace connectivity check (smoke-test route)
# ---------------------------------------------------------------------------


def get_current_user() -> str:
    """Return the display name of the currently authenticated workspace user."""
    client = _get_client()
    try:
        me = client.current_user.me()
        return me.display_name or me.user_name or "unknown"
    except DatabricksServiceError:
        raise
    except DatabricksError as exc:
        raise DatabricksServiceError(
            "Databricks workspace call failed. Check logs for details."
        ) from exc
    except Exception as exc:
        raise DatabricksServiceError(
            "Databricks provider request failed. Check logs for details."
        ) from exc


# ---------------------------------------------------------------------------
# SQL statement execution
# ---------------------------------------------------------------------------


def _execute_statement(
    statement: str,
    parameters: Optional[list[StatementParameterListItem]] = None,
) -> StatementResponse:
    """Execute a SQL statement and return the SDK response.

    Inspects the returned ``StatementResponse.status.state`` and raises
    ``DatabricksServiceError`` for any non-SUCCEEDED terminal state.  This
    prevents callers from silently treating a failed statement as a success.

    The raw Databricks error message is logged internally for debugging but
    is NOT propagated through ``DatabricksServiceError`` to avoid leaking
    sensitive provider information through API responses.

    Args:
        statement: The SQL text to execute.
        parameters: Optional list of named parameters.

    Returns:
        The ``StatementResponse`` when the statement succeeds.

    Raises:
        DatabricksServiceError: if warehouse/profile config is missing,
            the statement execution fails, or an SDK exception is raised.
    """
    if not settings.databricks_warehouse_id:
        raise DatabricksServiceError(
            "DATABRICKS_WAREHOUSE_ID is not set. "
            "Add it to your environment or .env file."
        )

    client = _get_client()

    try:
        response: StatementResponse = client.statement_execution.execute_statement(
            statement=statement,
            warehouse_id=settings.databricks_warehouse_id,
            catalog=settings.databricks_catalog,
            schema=settings.databricks_schema,
            parameters=parameters,
            wait_timeout="30s",
        )
    except DatabricksError as exc:
        # SDK raised — network/auth/config problem.
        logger.error("Databricks SDK error during statement execution: %s", exc)
        raise DatabricksServiceError(
            "Databricks SQL execution failed. Check logs for details."
        ) from exc
    except Exception as exc:
        logger.error("Unexpected error during Databricks statement execution: %s", exc)
        raise DatabricksServiceError(
            "Databricks SQL execution failed. Check logs for details."
        ) from exc

    # Inspect the returned status — the SDK does NOT raise on statement failure.
    status = response.status
    state = status.state if status else None

    if state is not StatementState.SUCCEEDED:
        error_msg: Optional[str] = None
        if status and status.error:
            error_msg = status.error.message
        logger.error(
            "Databricks statement finished with state=%s error=%r sql=%s",
            state,
            error_msg,
            statement[:120],
        )
        raise DatabricksServiceError(
            f"Databricks statement did not succeed (state={state}). "
            "Check logs for details."
        )

    return response


# ---------------------------------------------------------------------------
# Table setup  (idempotent — creates all required tables)
# ---------------------------------------------------------------------------


def setup_tables() -> None:
    """Idempotent DDL for all Echelon application tables.

    Creates:
    - ``student_profiles``
    - ``opportunities``

    Compatible with the live environment:
    - No DEFAULT CURRENT_TIMESTAMP() (column defaults disabled).
    - No PRIMARY KEY declaration.
    - USING DELTA storage.
    """
    _execute_statement("""
    CREATE TABLE IF NOT EXISTS student_profiles (
        firebase_uid  STRING NOT NULL,
        major         STRING,
        class_year    STRING,
        bio           STRING,
        skills        ARRAY<STRING>,
        interests     ARRAY<STRING>,
        coursework    ARRAY<STRING>,
        experience    ARRAY<STRING>,
        created_at    TIMESTAMP,
        updated_at    TIMESTAMP
    )
    USING DELTA
    """)

    _execute_statement("""
    CREATE TABLE IF NOT EXISTS opportunities (
        id               STRING NOT NULL,
        title            STRING NOT NULL,
        organization     STRING NOT NULL,
        opportunity_type STRING NOT NULL,
        description      STRING NOT NULL,
        source_url       STRING NOT NULL,
        skills           ARRAY<STRING>,
        interests        ARRAY<STRING>,
        eligibility      ARRAY<STRING>,
        majors           ARRAY<STRING>,
        class_years      ARRAY<STRING>,
        location         STRING,
        time_commitment  STRING,
        compensation     STRING,
        deadline         STRING,
        apply_url        STRING,
        contact_name     STRING,
        contact_email    STRING,
        created_at       TIMESTAMP,
        updated_at       TIMESTAMP
    )
    USING DELTA
    """)


# ---------------------------------------------------------------------------
# Profile persistence
# ---------------------------------------------------------------------------


def save_student_profile(firebase_uid: str, profile: StudentProfile) -> None:
    """Upsert a student profile into Databricks keyed by Firebase UID.

    Because column defaults are disabled in this environment, timestamps are
    set explicitly:
    - INSERT: both ``created_at`` and ``updated_at`` are set to
      ``CURRENT_TIMESTAMP()``.
    - UPDATE: ``created_at`` is preserved from the existing row; only
      ``updated_at`` is refreshed.
    """
    statement = """
    MERGE INTO student_profiles t
    USING (
        SELECT
            :uid        AS firebase_uid,
            :major      AS major,
            :class_year AS class_year,
            :bio        AS bio,
            from_json(:skills,     'ARRAY<STRING>') AS skills,
            from_json(:interests,  'ARRAY<STRING>') AS interests,
            from_json(:coursework, 'ARRAY<STRING>') AS coursework,
            from_json(:experience, 'ARRAY<STRING>') AS experience
    ) s
    ON t.firebase_uid = s.firebase_uid
    WHEN MATCHED THEN UPDATE SET
        t.major       = s.major,
        t.class_year  = s.class_year,
        t.bio         = s.bio,
        t.skills      = s.skills,
        t.interests   = s.interests,
        t.coursework  = s.coursework,
        t.experience  = s.experience,
        t.updated_at  = CURRENT_TIMESTAMP()
    WHEN NOT MATCHED THEN INSERT (
        firebase_uid, major, class_year, bio,
        skills, interests, coursework, experience,
        created_at, updated_at
    ) VALUES (
        s.firebase_uid, s.major, s.class_year, s.bio,
        s.skills, s.interests, s.coursework, s.experience,
        CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()
    )
    """

    parameters = [
        StatementParameterListItem(name="uid",        value=firebase_uid,                   type="STRING"),
        StatementParameterListItem(name="major",      value=profile.major or "",            type="STRING"),
        StatementParameterListItem(name="class_year", value=profile.class_year or "",       type="STRING"),
        StatementParameterListItem(name="bio",        value=profile.bio or "",              type="STRING"),
        StatementParameterListItem(name="skills",     value=json.dumps(profile.skills),     type="STRING"),
        StatementParameterListItem(name="interests",  value=json.dumps(profile.interests),  type="STRING"),
        StatementParameterListItem(name="coursework", value=json.dumps(profile.coursework), type="STRING"),
        StatementParameterListItem(name="experience", value=json.dumps(profile.experience), type="STRING"),
    ]

    _execute_statement(statement, parameters)


# ---------------------------------------------------------------------------
# Profile retrieval
# ---------------------------------------------------------------------------


def get_student_profile(firebase_uid: str) -> Optional[StudentProfile]:
    """Retrieve a student profile from Databricks by Firebase UID.

    Returns ``None`` if no profile exists for the given UID.
    """
    statement = """
    SELECT major, class_year, bio, skills, interests, coursework, experience
    FROM student_profiles
    WHERE firebase_uid = :uid
    """
    parameters = [StatementParameterListItem(name="uid", value=firebase_uid, type="STRING")]

    response = _execute_statement(statement, parameters)

    if not response.manifest or response.manifest.total_row_count == 0:
        return None

    data = response.result.data_array if response.result else None
    if not data:
        return None

    row = data[0]
    return StudentProfile(
        major=row[0] if row[0] else None,
        class_year=row[1] if row[1] else None,
        bio=row[2] if row[2] else None,
        skills=json.loads(row[3]) if row[3] else [],
        interests=json.loads(row[4]) if row[4] else [],
        coursework=json.loads(row[5]) if row[5] else [],
        experience=json.loads(row[6]) if row[6] else [],
    )


# ---------------------------------------------------------------------------
# Opportunity persistence
# ---------------------------------------------------------------------------

# Column order for SELECT used by both get_opportunity() and list_opportunities().
# Must match the SELECT in those queries exactly.
_OPP_SELECT_COLS = (
    "id, title, organization, opportunity_type, description, source_url, "
    "skills, interests, eligibility, majors, class_years, "
    "location, time_commitment, compensation, deadline, apply_url, "
    "contact_name, contact_email"
)


def _row_to_opportunity(row: list) -> Opportunity:
    """Deserialize a Databricks result row into an ``Opportunity``.

    Column order must match ``_OPP_SELECT_COLS``.

    List fields are stored as JSON strings and decoded with ``json.loads``.
    """
    return Opportunity(
        id=row[0],
        title=row[1],
        organization=row[2],
        opportunity_type=row[3],
        description=row[4],
        source_url=row[5],
        skills=json.loads(row[6]) if row[6] else [],
        interests=json.loads(row[7]) if row[7] else [],
        eligibility=json.loads(row[8]) if row[8] else [],
        majors=json.loads(row[9]) if row[9] else [],
        class_years=json.loads(row[10]) if row[10] else [],
        location=row[11] or None,
        time_commitment=row[12] or None,
        compensation=row[13] or None,
        deadline=row[14] or None,
        apply_url=row[15] or None,
        contact_name=row[16] or None,
        contact_email=row[17] or None,
    )


def save_opportunity(opportunity: Opportunity) -> None:
    """Upsert an opportunity into Databricks keyed by ``opportunity.id``.

    Because column defaults are disabled in this environment, timestamps are
    set explicitly:
    - INSERT: both ``created_at`` and ``updated_at`` are set to
      ``CURRENT_TIMESTAMP()``.
    - UPDATE: ``created_at`` is preserved from the existing row; only
      ``updated_at`` is refreshed.

    List fields are serialized as JSON strings via ``from_json()`` so
    Databricks can cast them back to ``ARRAY<STRING>`` natively.

    Never call this with fabricated data — ``source_url`` is required and
    must point to a real opportunity listing.
    """
    statement = """
    MERGE INTO opportunities t
    USING (
        SELECT
            :id               AS id,
            :title            AS title,
            :organization     AS organization,
            :opportunity_type AS opportunity_type,
            :description      AS description,
            :source_url       AS source_url,
            from_json(:skills,       'ARRAY<STRING>') AS skills,
            from_json(:interests,    'ARRAY<STRING>') AS interests,
            from_json(:eligibility,  'ARRAY<STRING>') AS eligibility,
            from_json(:majors,       'ARRAY<STRING>') AS majors,
            from_json(:class_years,  'ARRAY<STRING>') AS class_years,
            :location         AS location,
            :time_commitment  AS time_commitment,
            :compensation     AS compensation,
            :deadline         AS deadline,
            :apply_url        AS apply_url,
            :contact_name     AS contact_name,
            :contact_email    AS contact_email
    ) s
    ON t.id = s.id
    WHEN MATCHED THEN UPDATE SET
        t.title            = s.title,
        t.organization     = s.organization,
        t.opportunity_type = s.opportunity_type,
        t.description      = s.description,
        t.source_url       = s.source_url,
        t.skills           = s.skills,
        t.interests        = s.interests,
        t.eligibility      = s.eligibility,
        t.majors           = s.majors,
        t.class_years      = s.class_years,
        t.location         = s.location,
        t.time_commitment  = s.time_commitment,
        t.compensation     = s.compensation,
        t.deadline         = s.deadline,
        t.apply_url        = s.apply_url,
        t.contact_name     = s.contact_name,
        t.contact_email    = s.contact_email,
        t.updated_at       = CURRENT_TIMESTAMP()
    WHEN NOT MATCHED THEN INSERT (
        id, title, organization, opportunity_type, description, source_url,
        skills, interests, eligibility, majors, class_years,
        location, time_commitment, compensation, deadline, apply_url,
        contact_name, contact_email,
        created_at, updated_at
    ) VALUES (
        s.id, s.title, s.organization, s.opportunity_type, s.description, s.source_url,
        s.skills, s.interests, s.eligibility, s.majors, s.class_years,
        s.location, s.time_commitment, s.compensation, s.deadline, s.apply_url,
        s.contact_name, s.contact_email,
        CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()
    )
    """

    parameters = [
        StatementParameterListItem(name="id",               value=opportunity.id,                          type="STRING"),
        StatementParameterListItem(name="title",            value=opportunity.title,                       type="STRING"),
        StatementParameterListItem(name="organization",     value=opportunity.organization,                type="STRING"),
        StatementParameterListItem(name="opportunity_type", value=opportunity.opportunity_type,            type="STRING"),
        StatementParameterListItem(name="description",      value=opportunity.description,                 type="STRING"),
        StatementParameterListItem(name="source_url",       value=opportunity.source_url,                  type="STRING"),
        StatementParameterListItem(name="skills",           value=json.dumps(opportunity.skills),          type="STRING"),
        StatementParameterListItem(name="interests",        value=json.dumps(opportunity.interests),       type="STRING"),
        StatementParameterListItem(name="eligibility",      value=json.dumps(opportunity.eligibility),     type="STRING"),
        StatementParameterListItem(name="majors",           value=json.dumps(opportunity.majors),          type="STRING"),
        StatementParameterListItem(name="class_years",      value=json.dumps(opportunity.class_years),     type="STRING"),
        StatementParameterListItem(name="location",         value=opportunity.location or "",              type="STRING"),
        StatementParameterListItem(name="time_commitment",  value=opportunity.time_commitment or "",       type="STRING"),
        StatementParameterListItem(name="compensation",     value=opportunity.compensation or "",          type="STRING"),
        StatementParameterListItem(name="deadline",         value=opportunity.deadline or "",              type="STRING"),
        StatementParameterListItem(name="apply_url",        value=opportunity.apply_url or "",             type="STRING"),
        StatementParameterListItem(name="contact_name",     value=opportunity.contact_name or "",          type="STRING"),
        StatementParameterListItem(name="contact_email",    value=opportunity.contact_email or "",         type="STRING"),
    ]

    _execute_statement(statement, parameters)


def save_opportunities(opportunities: list[Opportunity]) -> None:
    """Upsert a batch of opportunities.

    Calls ``save_opportunity()`` for each entry.  Suitable for small initial
    seed loads; do not use for high-volume ingestion.
    """
    for opp in opportunities:
        save_opportunity(opp)


def get_opportunity(opportunity_id: str) -> Optional[Opportunity]:
    """Retrieve a single opportunity from Databricks by ID.

    Returns ``None`` if no opportunity exists with the given ID.
    """
    statement = f"""
    SELECT {_OPP_SELECT_COLS}
    FROM opportunities
    WHERE id = :id
    """
    parameters = [StatementParameterListItem(name="id", value=opportunity_id, type="STRING")]

    response = _execute_statement(statement, parameters)

    if not response.manifest or response.manifest.total_row_count == 0:
        return None

    data = response.result.data_array if response.result else None
    if not data:
        return None

    return _row_to_opportunity(data[0])


def list_opportunities(limit: int = 100) -> list[Opportunity]:
    """Return up to ``limit`` opportunities from Databricks.

    Results are ordered by ``created_at`` descending (newest first).
    """
    statement = f"""
    SELECT {_OPP_SELECT_COLS}
    FROM opportunities
    ORDER BY created_at DESC
    LIMIT :lim
    """
    parameters = [StatementParameterListItem(name="lim", value=str(limit), type="INT")]

    response = _execute_statement(statement, parameters)

    if not response.manifest or response.manifest.total_row_count == 0:
        return []

    data = response.result.data_array if response.result else None
    if not data:
        return []

    return [_row_to_opportunity(row) for row in data]
