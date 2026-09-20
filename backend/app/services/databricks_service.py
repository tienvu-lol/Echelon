"""Databricks workspace service.

Wraps the Databricks Python SDK (WorkspaceClient) and exposes entry points
used by route handlers.  All provider-specific logic lives here; routes
stay thin.
"""

import json

from databricks.sdk import WorkspaceClient
from databricks.sdk.errors import DatabricksError
from databricks.sdk.service.sql import StatementParameterListItem

from app.core.config import settings
from app.models.opportunity import Opportunity
from app.models.recommendation import CareerPreferences
from app.models.student import StudentProfile


class DatabricksServiceError(Exception):
    """Raised when the Databricks service cannot fulfil a request."""


def _get_client() -> WorkspaceClient:
    """Build and return a configured WorkspaceClient."""
    if not settings.databricks_config_profile:
        raise DatabricksServiceError("DATABRICKS_CONFIG_PROFILE is not set")
    kwargs = {}
    if settings.databricks_config_profile:
        kwargs["profile"] = settings.databricks_config_profile
    return WorkspaceClient(**kwargs)


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


def _execute_statement(
    statement: str, parameters: list[StatementParameterListItem] = None
):
    """Executes a SQL statement via Databricks SDK."""
    if not settings.databricks_warehouse_id:
        raise DatabricksServiceError("DATABRICKS_WAREHOUSE_ID is not set.")

    client = _get_client()

    try:
        response = client.statement_execution.execute_statement(
            statement=statement,
            warehouse_id=settings.databricks_warehouse_id,
            catalog=settings.databricks_catalog,
            schema=settings.databricks_schema,
            parameters=parameters,
            wait_timeout="50s",
        )
        return response
    except Exception as e:
        raise DatabricksServiceError(f"Failed to execute Databricks SQL: {e!s}") from e


def setup_tables():
    """Idempotent setup for Databricks tables."""
    profile_sql = """
    CREATE TABLE IF NOT EXISTS student_profiles (
        firebase_uid STRING NOT NULL,
        major STRING,
        class_year STRING,
        bio STRING,
        skills ARRAY<STRING>,
        interests ARRAY<STRING>,
        coursework ARRAY<STRING>,
        experience ARRAY<STRING>,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
        PRIMARY KEY (firebase_uid)
    )
    """
    _execute_statement(profile_sql)

    pref_sql = """
    CREATE TABLE IF NOT EXISTS career_preferences (
        firebase_uid STRING NOT NULL,
        career_tracks STRING,
        preferred_role_types ARRAY<STRING>,
        preferred_locations ARRAY<STRING>,
        remote_preference STRING,
        industries_of_interest ARRAY<STRING>,
        technologies_to_use ARRAY<STRING>,
        technologies_to_learn ARRAY<STRING>,
        research_vs_industry STRING,
        startup_vs_large_company STRING,
        career_goals STRING,
        other_preferences STRING,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
        PRIMARY KEY (firebase_uid)
    )
    """
    _execute_statement(pref_sql)

    opp_sql = """
    CREATE TABLE IF NOT EXISTS opportunities (
        id STRING NOT NULL,
        title STRING,
        organization STRING,
        opportunity_type STRING,
        description STRING,
        source_url STRING,
        source_name STRING,
        source_age STRING,
        active BOOLEAN,
        first_seen_at TIMESTAMP,
        last_seen_at TIMESTAMP,
        skills ARRAY<STRING>,
        interests ARRAY<STRING>,
        eligibility ARRAY<STRING>,
        majors ARRAY<STRING>,
        class_years ARRAY<STRING>,
        school_restrictions ARRAY<STRING>,
        eligibility_notes ARRAY<STRING>,
        degree_levels ARRAY<STRING>,
        work_authorization_requirements ARRAY<STRING>,
        career_tracks STRING,
        location STRING,
        remote_status STRING,
        time_commitment STRING,
        compensation STRING,
        deadline STRING,
        apply_url STRING,
        contact_name STRING,
        contact_email STRING,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
        PRIMARY KEY (id)
    )
    """
    _execute_statement(opp_sql)


def save_student_profile(firebase_uid: str, profile: StudentProfile) -> None:
    statement = """
    MERGE INTO student_profiles t
    USING (
        SELECT 
            :uid as firebase_uid, 
            :major as major, 
            :class_year as class_year, 
            :bio as bio, 
            from_json(:skills, 'ARRAY<STRING>') as skills,
            from_json(:interests, 'ARRAY<STRING>') as interests,
            from_json(:coursework, 'ARRAY<STRING>') as coursework,
            from_json(:experience, 'ARRAY<STRING>') as experience
    ) s
    ON t.firebase_uid = s.firebase_uid
    WHEN MATCHED THEN UPDATE SET
        t.major = s.major,
        t.class_year = s.class_year,
        t.bio = s.bio,
        t.skills = s.skills,
        t.interests = s.interests,
        t.coursework = s.coursework,
        t.experience = s.experience,
        t.updated_at = CURRENT_TIMESTAMP()
    WHEN NOT MATCHED THEN INSERT
        (firebase_uid, major, class_year, bio, skills, interests, coursework, experience)
    VALUES
        (s.firebase_uid, s.major, s.class_year, s.bio, s.skills, s.interests, s.coursework, s.experience)
    """

    parameters = [
        StatementParameterListItem(name="uid", value=firebase_uid, type="STRING"),
        StatementParameterListItem(
            name="major", value=profile.major or "", type="STRING"
        ),
        StatementParameterListItem(
            name="class_year", value=profile.class_year or "", type="STRING"
        ),
        StatementParameterListItem(name="bio", value=profile.bio or "", type="STRING"),
        StatementParameterListItem(
            name="skills", value=json.dumps(profile.skills), type="STRING"
        ),
        StatementParameterListItem(
            name="interests", value=json.dumps(profile.interests), type="STRING"
        ),
        StatementParameterListItem(
            name="coursework", value=json.dumps(profile.coursework), type="STRING"
        ),
        StatementParameterListItem(
            name="experience", value=json.dumps(profile.experience), type="STRING"
        ),
    ]

    _execute_statement(statement, parameters)


def get_student_profile(firebase_uid: str) -> StudentProfile | None:
    statement = """
    SELECT major, class_year, bio, skills, interests, coursework, experience
    FROM student_profiles
    WHERE firebase_uid = :uid
    """
    parameters = [
        StatementParameterListItem(name="uid", value=firebase_uid, type="STRING")
    ]
    response = _execute_statement(statement, parameters)

    if not response.manifest or response.manifest.total_row_count == 0:
        return None

    data = response.result.data_array
    if not data or len(data) == 0:
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


def save_career_preferences(firebase_uid: str, prefs: CareerPreferences) -> None:
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
         startup_vs_large_company, career_goals, other_preferences)
    VALUES
        (s.firebase_uid, s.career_tracks, s.preferred_role_types, s.preferred_locations, s.remote_preference,
         s.industries_of_interest, s.technologies_to_use, s.technologies_to_learn, s.research_vs_industry,
         s.startup_vs_large_company, s.career_goals, s.other_preferences)
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


def get_career_preferences(firebase_uid: str) -> CareerPreferences | None:
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

    data = response.result.data_array
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


def upsert_opportunities(opportunities: list[Opportunity]):
    """Batch upserts opportunities into Databricks."""
    for opp in opportunities:
        statement = """
        MERGE INTO opportunities t
        USING (
            SELECT 
                :id as id, :title as title, :organization as organization, 
                :opportunity_type as opportunity_type, :description as description, 
                :source_url as source_url, :source_name as source_name, :source_age as source_age, 
                :active as active, :first_seen_at as first_seen_at, :last_seen_at as last_seen_at, 
                from_json(:skills, 'ARRAY<STRING>') as skills,
                from_json(:interests, 'ARRAY<STRING>') as interests,
                from_json(:eligibility, 'ARRAY<STRING>') as eligibility,
                from_json(:majors, 'ARRAY<STRING>') as majors,
                from_json(:class_years, 'ARRAY<STRING>') as class_years,
                from_json(:school_restrictions, 'ARRAY<STRING>') as school_restrictions,
                from_json(:eligibility_notes, 'ARRAY<STRING>') as eligibility_notes,
                from_json(:degree_levels, 'ARRAY<STRING>') as degree_levels,
                from_json(:work_authorization_requirements, 'ARRAY<STRING>') as work_authorization_requirements,
                :career_tracks as career_tracks, :location as location, :remote_status as remote_status,
                :time_commitment as time_commitment, :compensation as compensation, 
                :deadline as deadline, :apply_url as apply_url, 
                :contact_name as contact_name, :contact_email as contact_email
        ) s
        ON t.id = s.id
        WHEN MATCHED THEN UPDATE SET
            t.title = s.title, t.organization = s.organization, t.opportunity_type = s.opportunity_type,
            t.description = s.description, t.source_url = s.source_url, t.source_name = s.source_name,
            t.source_age = s.source_age, t.active = s.active, t.last_seen_at = s.last_seen_at,
            t.skills = s.skills, t.interests = s.interests, t.eligibility = s.eligibility,
            t.majors = s.majors, t.class_years = s.class_years, t.school_restrictions = s.school_restrictions,
            t.eligibility_notes = s.eligibility_notes, t.degree_levels = s.degree_levels,
            t.work_authorization_requirements = s.work_authorization_requirements,
            t.career_tracks = s.career_tracks, t.location = s.location, t.remote_status = s.remote_status,
            t.time_commitment = s.time_commitment, t.compensation = s.compensation, t.deadline = s.deadline,
            t.apply_url = s.apply_url, t.contact_name = s.contact_name, t.contact_email = s.contact_email,
            t.updated_at = CURRENT_TIMESTAMP()
        WHEN NOT MATCHED THEN INSERT
            (id, title, organization, opportunity_type, description, source_url, source_name, source_age, active,
             first_seen_at, last_seen_at, skills, interests, eligibility, majors, class_years, school_restrictions,
             eligibility_notes, degree_levels, work_authorization_requirements, career_tracks, location, remote_status,
             time_commitment, compensation, deadline, apply_url, contact_name, contact_email)
        VALUES
            (s.id, s.title, s.organization, s.opportunity_type, s.description, s.source_url, s.source_name, s.source_age, s.active,
             s.first_seen_at, s.last_seen_at, s.skills, s.interests, s.eligibility, s.majors, s.class_years, s.school_restrictions,
             s.eligibility_notes, s.degree_levels, s.work_authorization_requirements, s.career_tracks, s.location, s.remote_status,
             s.time_commitment, s.compensation, s.deadline, s.apply_url, s.contact_name, s.contact_email)
        """

        parameters = [
            StatementParameterListItem(name="id", value=opp.id, type="STRING"),
            StatementParameterListItem(name="title", value=opp.title, type="STRING"),
            StatementParameterListItem(
                name="organization", value=opp.organization, type="STRING"
            ),
            StatementParameterListItem(
                name="opportunity_type", value=opp.opportunity_type, type="STRING"
            ),
            StatementParameterListItem(
                name="description", value=opp.description, type="STRING"
            ),
            StatementParameterListItem(
                name="source_url", value=opp.source_url, type="STRING"
            ),
            StatementParameterListItem(
                name="source_name", value=opp.source_name, type="STRING"
            ),
            StatementParameterListItem(
                name="source_age", value=opp.source_age or "", type="STRING"
            ),
            StatementParameterListItem(
                name="active", value="true" if opp.active else "false", type="BOOLEAN"
            ),
            StatementParameterListItem(
                name="first_seen_at",
                value=opp.first_seen_at.isoformat() if opp.first_seen_at else "",
                type="TIMESTAMP",
            ),
            StatementParameterListItem(
                name="last_seen_at",
                value=opp.last_seen_at.isoformat() if opp.last_seen_at else "",
                type="TIMESTAMP",
            ),
            StatementParameterListItem(
                name="skills", value=json.dumps(opp.skills), type="STRING"
            ),
            StatementParameterListItem(
                name="interests", value=json.dumps(opp.interests), type="STRING"
            ),
            StatementParameterListItem(
                name="eligibility", value=json.dumps(opp.eligibility), type="STRING"
            ),
            StatementParameterListItem(
                name="majors", value=json.dumps(opp.majors), type="STRING"
            ),
            StatementParameterListItem(
                name="class_years", value=json.dumps(opp.class_years), type="STRING"
            ),
            StatementParameterListItem(
                name="school_restrictions",
                value=json.dumps(opp.school_restrictions),
                type="STRING",
            ),
            StatementParameterListItem(
                name="eligibility_notes",
                value=json.dumps(opp.eligibility_notes),
                type="STRING",
            ),
            StatementParameterListItem(
                name="degree_levels", value=json.dumps(opp.degree_levels), type="STRING"
            ),
            StatementParameterListItem(
                name="work_authorization_requirements",
                value=json.dumps(opp.work_authorization_requirements),
                type="STRING",
            ),
            StatementParameterListItem(
                name="career_tracks",
                value=json.dumps([ct.model_dump() for ct in opp.career_tracks]),
                type="STRING",
            ),
            StatementParameterListItem(
                name="location", value=opp.location or "", type="STRING"
            ),
            StatementParameterListItem(
                name="remote_status", value=opp.remote_status or "", type="STRING"
            ),
            StatementParameterListItem(
                name="time_commitment", value=opp.time_commitment or "", type="STRING"
            ),
            StatementParameterListItem(
                name="compensation", value=opp.compensation or "", type="STRING"
            ),
            StatementParameterListItem(
                name="deadline", value=opp.deadline or "", type="STRING"
            ),
            StatementParameterListItem(
                name="apply_url", value=opp.apply_url or "", type="STRING"
            ),
            StatementParameterListItem(
                name="contact_name", value=opp.contact_name or "", type="STRING"
            ),
            StatementParameterListItem(
                name="contact_email", value=opp.contact_email or "", type="STRING"
            ),
        ]

        _execute_statement(statement, parameters)


def get_active_opportunities() -> list[Opportunity]:
    """Retrieves all active opportunities."""
    statement = "SELECT * FROM opportunities WHERE active = true LIMIT 500"
    response = _execute_statement(statement)

    opportunities = []
    if not response.manifest or response.manifest.total_row_count == 0:
        return opportunities

    data = response.result.data_array
    schema = {col.name: idx for idx, col in enumerate(response.manifest.schema.columns)}

    for row in data:

        def get_val(name, default=None, is_json=False):
            if name not in schema:
                return default
            val = row[schema[name]]
            if val is None or val == "null" or val == "":
                return default
            if is_json:
                return json.loads(val)
            return val

        try:
            opp = Opportunity(
                id=get_val("id"),
                title=get_val("title"),
                organization=get_val("organization"),
                opportunity_type=get_val("opportunity_type"),
                description=get_val("description", ""),
                source_url=get_val("source_url", ""),
                source_name=get_val("source_name", "Unknown"),
                source_age=get_val("source_age"),
                active=get_val("active") == "true",
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
            opportunities.append(opp)
        except Exception:
            continue

    return opportunities
