"""Databricks workspace service.

Wraps the Databricks Python SDK (WorkspaceClient) and exposes entry points
used by route handlers. All provider-specific logic lives here; routes
stay thin.

The SDK is fully synchronous. FastAPI runs synchronous route handlers in a
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
from app.models.recommendation import CareerPreferences
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
    ``DATABRICKS_CONFIG_PROFILE``. No PATs or hardcoded credentials.

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
    ``DatabricksServiceError`` for any non-SUCCEEDED terminal state. This
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
            wait_timeout="50s",
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
# Table setup (idempotent — creates all required tables)
# ---------------------------------------------------------------------------


def setup_tables(include_career_preferences: bool = False) -> None:
    """Idempotent DDL for all Echelon application tables.

    Creates:
    - ``student_profiles``
    - ``opportunities``
    - optionally ``career_preferences``

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
        id                              STRING NOT NULL,
        title                           STRING NOT NULL,
        organization                    STRING NOT NULL,
        opportunity_type                STRING NOT NULL,
        description                     STRING NOT NULL,
        source_url                      STRING NOT NULL,
        source_name                     STRING,
        source_age                      STRING,
        active                          BOOLEAN,
        first_seen_at                   TIMESTAMP,
        last_seen_at                    TIMESTAMP,
        skills                          ARRAY<STRING>,
        interests                       ARRAY<STRING>,
        eligibility                     ARRAY<STRING>,
        majors                          ARRAY<STRING>,
        class_years                     ARRAY<STRING>,
        school_restrictions             ARRAY<STRING>,
        eligibility_notes               ARRAY<STRING>,
        degree_levels                   ARRAY<STRING>,
        work_authorization_requirements ARRAY<STRING>,
        career_tracks                   STRING,
        location                        STRING,
        remote_status                   STRING,
        time_commitment                 STRING,
        compensation                    STRING,
        deadline                        STRING,
        apply_url                       STRING,
        contact_name                    STRING,
        contact_email                   STRING,
        created_at                      TIMESTAMP,
        updated_at                      TIMESTAMP
    )
    USING DELTA
    """)

    if include_career_preferences:
        setup_career_preferences_table()


def setup_career_preferences_table() -> None:
    """Idempotent DDL for the career_preferences table."""
    _execute_statement("""
    CREATE TABLE IF NOT EXISTS career_preferences (
        firebase_uid            STRING NOT NULL,
        career_tracks           STRING,
        preferred_role_types    ARRAY<STRING>,
        preferred_locations     ARRAY<STRING>,
        remote_preference       STRING,
        industries_of_interest  ARRAY<STRING>,
        technologies_to_use     ARRAY<STRING>,
        technologies_to_learn   ARRAY<STRING>,
        research_vs_industry    STRING,
        startup_vs_large_company STRING,
        career_goals            STRING,
        other_preferences       STRING,
        created_at              TIMESTAMP,
        updated_at              TIMESTAMP
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
# Career Preferences persistence
# ---------------------------------------------------------------------------


def save_career_preferences(firebase_uid: str, prefs: CareerPreferences) -> None:
    """Upsert student career preferences into Databricks keyed by Firebase UID."""
    statement = """
    MERGE INTO career_preferences t
    USING (
        SELECT 
            :uid as firebase_uid, 
            :career_tracks as career_tracks,
            from_json(:preferred_role_types, 'ARRAY<STRING>') as preferred_role_types,
            from_json(:preferred_locations, 'ARRAY<STRING>') as preferred_locations,
            :remote_preference as remote_preference,
            from_json(:industries_of_interest, 'ARRAY<STRING>') as industries_of_interest,
            from_json(:technologies_to_use, 'ARRAY<STRING>') as technologies_to_use,
            from_json(:technologies_to_learn, 'ARRAY<STRING>') as technologies_to_learn,
            :research_vs_industry as research_vs_industry,
            :startup_vs_large_company as startup_vs_large_company,
            :career_goals as career_goals,
            :other_preferences as other_preferences
    ) s
    ON t.firebase_uid = s.firebase_uid
    WHEN MATCHED THEN UPDATE SET
        t.career_tracks = s.career_tracks,
        t.preferred_role_types = s.preferred_role_types,
        t.preferred_locations = s.preferred_locations,
        t.remote_preference = s.remote_preference,
        t.industries_of_interest = s.industries_of_interest,
        t.technologies_to_use = s.technologies_to_use,
        t.technologies_to_learn = s.technologies_to_learn,
        t.research_vs_industry = s.research_vs_industry,
        t.startup_vs_large_company = s.startup_vs_large_company,
        t.career_goals = s.career_goals,
        t.other_preferences = s.other_preferences,
        t.updated_at = CURRENT_TIMESTAMP()
    WHEN NOT MATCHED THEN INSERT
        (firebase_uid, career_tracks, preferred_role_types, preferred_locations, remote_preference,
         industries_of_interest, technologies_to_use, technologies_to_learn, research_vs_industry,
         startup_vs_large_company, career_goals, other_preferences, created_at, updated_at)
    VALUES
        (s.firebase_uid, s.career_tracks, s.preferred_role_types, s.preferred_locations, s.remote_preference,
         s.industries_of_interest, s.technologies_to_use, s.technologies_to_learn, s.research_vs_industry,
         s.startup_vs_large_company, s.career_goals, s.other_preferences, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP())
    """

    parameters = [
        StatementParameterListItem(name="uid", value=firebase_uid, type="STRING"),
        StatementParameterListItem(
            name="career_tracks",
            value=json.dumps([ct.model_dump() for ct in prefs.career_tracks]),
            type="STRING",
        ),
        StatementParameterListItem(
            name="preferred_role_types",
            value=json.dumps(prefs.preferred_role_types),
            type="STRING",
        ),
        StatementParameterListItem(
            name="preferred_locations",
            value=json.dumps(prefs.preferred_locations),
            type="STRING",
        ),
        StatementParameterListItem(
            name="remote_preference", value=prefs.remote_preference or "", type="STRING"
        ),
        StatementParameterListItem(
            name="industries_of_interest",
            value=json.dumps(prefs.industries_of_interest),
            type="STRING",
        ),
        StatementParameterListItem(
            name="technologies_to_use",
            value=json.dumps(prefs.technologies_to_use),
            type="STRING",
        ),
        StatementParameterListItem(
            name="technologies_to_learn",
            value=json.dumps(prefs.technologies_to_learn),
            type="STRING",
        ),
        StatementParameterListItem(
            name="research_vs_industry",
            value=prefs.research_vs_industry or "",
            type="STRING",
        ),
        StatementParameterListItem(
            name="startup_vs_large_company",
            value=prefs.startup_vs_large_company or "",
            type="STRING",
        ),
        StatementParameterListItem(
            name="career_goals", value=prefs.career_goals or "", type="STRING"
        ),
        StatementParameterListItem(
            name="other_preferences", value=prefs.other_preferences or "", type="STRING"
        ),
    ]

    _execute_statement(statement, parameters)


def get_career_preferences(firebase_uid: str) -> Optional[CareerPreferences]:
    """Retrieve career preferences from Databricks by Firebase UID."""
    statement = """
    SELECT 
        career_tracks, preferred_role_types, preferred_locations, remote_preference,
        industries_of_interest, technologies_to_use, technologies_to_learn,
        research_vs_industry, startup_vs_large_company, career_goals, other_preferences
    FROM career_preferences
    WHERE firebase_uid = :uid
    """
    parameters = [
        StatementParameterListItem(name="uid", value=firebase_uid, type="STRING")
    ]
    response = _execute_statement(statement, parameters)

    if not response.manifest or response.manifest.total_row_count == 0:
        return None

    data = response.result.data_array if response.result else None
    if not data or len(data) == 0:
        return None

    row = data[0]
    return CareerPreferences(
        career_tracks=json.loads(row[0]) if row[0] else [],
        preferred_role_types=json.loads(row[1]) if row[1] else [],
        preferred_locations=json.loads(row[2]) if row[2] else [],
        remote_preference=row[3] if row[3] else None,
        industries_of_interest=json.loads(row[4]) if row[4] else [],
        technologies_to_use=json.loads(row[5]) if row[5] else [],
        technologies_to_learn=json.loads(row[6]) if row[6] else [],
        research_vs_industry=row[7] if row[7] else None,
        startup_vs_large_company=row[8] if row[8] else None,
        career_goals=row[9] if row[9] else None,
        other_preferences=row[10] if row[10] else None,
    )


# ---------------------------------------------------------------------------
# Opportunity persistence
# ---------------------------------------------------------------------------

_OPP_SELECT_COLS = (
    "id, title, organization, opportunity_type, description, source_url, "
    "skills, interests, eligibility, majors, class_years, "
    "location, time_commitment, compensation, deadline, apply_url, "
    "contact_name, contact_email"
)


def _row_to_opportunity(row: list, schema: Optional[dict[str, int]] = None) -> Opportunity:
    """Deserialize a Databricks result row into an ``Opportunity``."""
    if schema:
        def get_val(name, default=None, is_json=False):
            if name not in schema:
                return default
            val = row[schema[name]]
            if val is None or val == "null" or val == "":
                return default
            if is_json:
                try:
                    return json.loads(val)
                except Exception:
                    return default
            return val

        return Opportunity(
            id=get_val("id"),
            title=get_val("title"),
            organization=get_val("organization"),
            opportunity_type=get_val("opportunity_type"),
            description=get_val("description", ""),
            source_url=get_val("source_url", ""),
            source_name=get_val("source_name", "Unknown"),
            source_age=get_val("source_age"),
            active=get_val("active") == "true" if isinstance(get_val("active"), str) else bool(get_val("active", True)),
            skills=get_val("skills", [], is_json=True),
            interests=get_val("interests", [], is_json=True),
            eligibility=get_val("eligibility", [], is_json=True),
            majors=get_val("majors", [], is_json=True),
            class_years=get_val("class_years", [], is_json=True),
            school_restrictions=get_val("school_restrictions", [], is_json=True),
            eligibility_notes=get_val("eligibility_notes", [], is_json=True),
            degree_levels=get_val("degree_levels", [], is_json=True),
            work_authorization_requirements=get_val(
                "work_authorization_requirements", [], is_json=True
            ),
            career_tracks=get_val("career_tracks", [], is_json=True),
            location=get_val("location"),
            remote_status=get_val("remote_status"),
            time_commitment=get_val("time_commitment"),
            compensation=get_val("compensation"),
            deadline=get_val("deadline"),
            apply_url=get_val("apply_url"),
            contact_name=get_val("contact_name"),
            contact_email=get_val("contact_email"),
        )

    # Positional mapping for _OPP_SELECT_COLS (matches test_opportunities.py)
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
    """Upsert an opportunity into Databricks keyed by ``opportunity.id``."""
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
            :source_name      AS source_name,
            :source_age       AS source_age,
            :active           AS active,
            :first_seen_at    AS first_seen_at,
            :last_seen_at     AS last_seen_at,
            from_json(:skills,       'ARRAY<STRING>') AS skills,
            from_json(:interests,    'ARRAY<STRING>') AS interests,
            from_json(:eligibility,  'ARRAY<STRING>') AS eligibility,
            from_json(:majors,       'ARRAY<STRING>') AS majors,
            from_json(:class_years,  'ARRAY<STRING>') AS class_years,
            from_json(:school_restrictions, 'ARRAY<STRING>') AS school_restrictions,
            from_json(:eligibility_notes,   'ARRAY<STRING>') AS eligibility_notes,
            from_json(:degree_levels,       'ARRAY<STRING>') AS degree_levels,
            from_json(:work_authorization_requirements, 'ARRAY<STRING>') AS work_authorization_requirements,
            :career_tracks    AS career_tracks,
            :location         AS location,
            :remote_status    AS remote_status,
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
        t.source_name      = s.source_name,
        t.source_age       = s.source_age,
        t.active           = s.active,
        t.last_seen_at     = s.last_seen_at,
        t.skills           = s.skills,
        t.interests        = s.interests,
        t.eligibility      = s.eligibility,
        t.majors           = s.majors,
        t.class_years      = s.class_years,
        t.school_restrictions = s.school_restrictions,
        t.eligibility_notes   = s.eligibility_notes,
        t.degree_levels       = s.degree_levels,
        t.work_authorization_requirements = s.work_authorization_requirements,
        t.career_tracks    = s.career_tracks,
        t.location         = s.location,
        t.remote_status    = s.remote_status,
        t.time_commitment  = s.time_commitment,
        t.compensation     = s.compensation,
        t.deadline         = s.deadline,
        t.apply_url        = s.apply_url,
        t.contact_name     = s.contact_name,
        t.contact_email    = s.contact_email,
        t.updated_at       = CURRENT_TIMESTAMP()
    WHEN NOT MATCHED THEN INSERT (
        id, title, organization, opportunity_type, description, source_url,
        source_name, source_age, active, first_seen_at, last_seen_at,
        skills, interests, eligibility, majors, class_years,
        school_restrictions, eligibility_notes, degree_levels,
        work_authorization_requirements, career_tracks,
        location, remote_status, time_commitment, compensation, deadline, apply_url,
        contact_name, contact_email,
        created_at, updated_at
    ) VALUES (
        s.id, s.title, s.organization, s.opportunity_type, s.description, s.source_url,
        s.source_name, s.source_age, s.active, s.first_seen_at, s.last_seen_at,
        s.skills, s.interests, s.eligibility, s.majors, s.class_years,
        s.school_restrictions, s.eligibility_notes, s.degree_levels,
        s.work_authorization_requirements, s.career_tracks,
        s.location, s.remote_status, s.time_commitment, s.compensation, s.deadline, s.apply_url,
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
        StatementParameterListItem(name="source_name",      value=opportunity.source_name,                 type="STRING"),
        StatementParameterListItem(name="source_age",       value=opportunity.source_age or "",            type="STRING"),
        StatementParameterListItem(name="active",           value="true" if opportunity.active else "false", type="BOOLEAN"),
        StatementParameterListItem(name="first_seen_at",    value=opportunity.first_seen_at.isoformat() if opportunity.first_seen_at else "", type="TIMESTAMP"),
        StatementParameterListItem(name="last_seen_at",     value=opportunity.last_seen_at.isoformat() if opportunity.last_seen_at else "",  type="TIMESTAMP"),
        StatementParameterListItem(name="skills",           value=json.dumps(opportunity.skills),          type="STRING"),
        StatementParameterListItem(name="interests",        value=json.dumps(opportunity.interests),       type="STRING"),
        StatementParameterListItem(name="eligibility",      value=json.dumps(opportunity.eligibility),     type="STRING"),
        StatementParameterListItem(name="majors",           value=json.dumps(opportunity.majors),          type="STRING"),
        StatementParameterListItem(name="class_years",      value=json.dumps(opportunity.class_years),     type="STRING"),
        StatementParameterListItem(name="school_restrictions", value=json.dumps(opportunity.school_restrictions), type="STRING"),
        StatementParameterListItem(name="eligibility_notes",   value=json.dumps(opportunity.eligibility_notes),   type="STRING"),
        StatementParameterListItem(name="degree_levels",       value=json.dumps(opportunity.degree_levels),       type="STRING"),
        StatementParameterListItem(name="work_authorization_requirements", value=json.dumps(opportunity.work_authorization_requirements), type="STRING"),
        StatementParameterListItem(name="career_tracks",    value=json.dumps([ct.model_dump() for ct in opportunity.career_tracks]), type="STRING"),
        StatementParameterListItem(name="location",         value=opportunity.location or "",              type="STRING"),
        StatementParameterListItem(name="remote_status",    value=opportunity.remote_status or "",         type="STRING"),
        StatementParameterListItem(name="time_commitment",  value=opportunity.time_commitment or "",       type="STRING"),
        StatementParameterListItem(name="compensation",     value=opportunity.compensation or "",          type="STRING"),
        StatementParameterListItem(name="deadline",         value=opportunity.deadline or "",              type="STRING"),
        StatementParameterListItem(name="apply_url",        value=opportunity.apply_url or "",             type="STRING"),
        StatementParameterListItem(name="contact_name",     value=opportunity.contact_name or "",          type="STRING"),
        StatementParameterListItem(name="contact_email",    value=opportunity.contact_email or "",         type="STRING"),
    ]

    _execute_statement(statement, parameters)


def save_opportunities(opportunities: list[Opportunity]) -> None:
    """Upsert a collection of opportunities."""
    for opp in opportunities:
        save_opportunity(opp)


def upsert_opportunities(opportunities: list[Opportunity]) -> None:
    """Batch upserts opportunities into Databricks (alias for save_opportunities)."""
    save_opportunities(opportunities)


def get_opportunity(opportunity_id: str) -> Optional[Opportunity]:
    """Retrieve a single opportunity from Databricks by ID."""
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

    schema = None
    if (
        response.manifest
        and hasattr(response.manifest, "schema")
        and response.manifest.schema
        and hasattr(response.manifest.schema, "columns")
        and response.manifest.schema.columns
    ):
        schema = {col.name: idx for idx, col in enumerate(response.manifest.schema.columns)}

    return _row_to_opportunity(data[0], schema=schema)


def list_opportunities(limit: int = 100) -> list[Opportunity]:
    """Return up to ``limit`` opportunities from Databricks, ordered by created_at DESC."""
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

    schema = None
    if (
        response.manifest
        and hasattr(response.manifest, "schema")
        and response.manifest.schema
        and hasattr(response.manifest.schema, "columns")
        and response.manifest.schema.columns
    ):
        schema = {col.name: idx for idx, col in enumerate(response.manifest.schema.columns)}

    return [_row_to_opportunity(row, schema=schema) for row in data]


def get_active_opportunities() -> list[Opportunity]:
    """Retrieves all active opportunities."""
    statement = "SELECT * FROM opportunities WHERE active = true LIMIT 500"
    response = _execute_statement(statement)

    if not response.manifest or response.manifest.total_row_count == 0:
        return []

    data = response.result.data_array if response.result else None
    if not data:
        return []

    schema = None
    if (
        response.manifest
        and hasattr(response.manifest, "schema")
        and response.manifest.schema
        and hasattr(response.manifest.schema, "columns")
        and response.manifest.schema.columns
    ):
        schema = {col.name: idx for idx, col in enumerate(response.manifest.schema.columns)}

    opportunities = []
    for row in data:
        try:
            opportunities.append(_row_to_opportunity(row, schema=schema))
        except Exception as exc:
            logger.warning("Failed to parse opportunity row: %s", exc)
            continue

    return opportunities
