"""Databricks workspace service.

Wraps the Databricks Python SDK (WorkspaceClient) and exposes entry points
used by route handlers.  All provider-specific logic lives here; routes
stay thin.
"""

from typing import Optional
import json
from databricks.sdk import WorkspaceClient
from databricks.sdk.service.sql import StatementParameterListItem
from databricks.sdk.errors import DatabricksError

from app.core.config import settings
from app.models.student import StudentProfile

class DatabricksServiceError(Exception):
    """Raised when the Databricks service cannot fulfil a request."""

def _get_client() -> WorkspaceClient:
    """Build and return a configured WorkspaceClient."""
    if not settings.databricks_config_profile:
        raise DatabricksServiceError(
            "DATABRICKS_CONFIG_PROFILE is not set. "
            "Add it to your environment or .env file."
        )
    return WorkspaceClient(profile=settings.databricks_config_profile)

def get_current_user() -> str:
    """Return the display name of the currently authenticated workspace user."""
    client = _get_client()
    try:
        me = client.current_user.me()
        return me.display_name or me.user_name or "unknown"
    except DatabricksServiceError:
        raise
    except DatabricksError as exc:
        raise DatabricksServiceError("Databricks workspace call failed. Check logs for details.") from exc
    except Exception as exc:
        raise DatabricksServiceError("Databricks provider request failed. Check logs for details.") from exc

def _execute_statement(statement: str, parameters: list[StatementParameterListItem] = None):
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
            wait_timeout="30s"
        )
        return response
    except Exception as e:
        raise DatabricksServiceError(f"Failed to execute Databricks SQL: {str(e)}") from e

def setup_tables():
    """Idempotent setup for Databricks tables."""
    statement = """
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
    _execute_statement(statement)

def save_student_profile(firebase_uid: str, profile: StudentProfile) -> None:
    """Upsert a student profile into Databricks keyed by Firebase UID."""
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
        StatementParameterListItem(name="major", value=profile.major or "", type="STRING"),
        StatementParameterListItem(name="class_year", value=profile.class_year or "", type="STRING"),
        StatementParameterListItem(name="bio", value=profile.bio or "", type="STRING"),
        StatementParameterListItem(name="skills", value=json.dumps(profile.skills), type="STRING"),
        StatementParameterListItem(name="interests", value=json.dumps(profile.interests), type="STRING"),
        StatementParameterListItem(name="coursework", value=json.dumps(profile.coursework), type="STRING"),
        StatementParameterListItem(name="experience", value=json.dumps(profile.experience), type="STRING")
    ]
    
    _execute_statement(statement, parameters)

def get_student_profile(firebase_uid: str) -> Optional[StudentProfile]:
    """Retrieve a student profile from Databricks by Firebase UID."""
    statement = """
    SELECT major, class_year, bio, skills, interests, coursework, experience
    FROM student_profiles
    WHERE firebase_uid = :uid
    """
    parameters = [StatementParameterListItem(name="uid", value=firebase_uid, type="STRING")]
    
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
