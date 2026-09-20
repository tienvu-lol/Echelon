"""Opportunity domain model.

Provider-independent.  No imports from Gemini, Databricks, or Firebase.
"""

from datetime import datetime

from pydantic import BaseModel, Field


class CareerTrackAffinity(BaseModel):
    """Represents how strongly a role matches a specific career track."""

    track: str
    weight: float


class Opportunity(BaseModel):
    """Represents a single campus opportunity (research, job, club, internship, etc.).

    Required fields are those a student needs to evaluate the opportunity.
    Optional fields are populated when available from the data source.
    All list fields use ``Field(default_factory=list)`` for isolation.
    """

    # --- Required ---
    id: str
    title: str
    organization: str
    opportunity_type: str
    description: str
    source_url: str

    # --- Ingestion & Source Metadata ---
    source_name: str = "Unknown"
    source_age: str | None = None
    active: bool = True
    first_seen_at: datetime | None = None
    last_seen_at: datetime | None = None

    # --- Filterable lists & Eligibility ---
    skills: list[str] = Field(default_factory=list)
    interests: list[str] = Field(default_factory=list)
    eligibility: list[str] = Field(default_factory=list)
    majors: list[str] = Field(default_factory=list)
    class_years: list[str] = Field(default_factory=list)
    school_restrictions: list[str] = Field(default_factory=list)
    eligibility_notes: list[str] = Field(default_factory=list)
    degree_levels: list[str] = Field(default_factory=list)
    work_authorization_requirements: list[str] = Field(default_factory=list)

    # --- Recommendations / Classifications ---
    career_tracks: list[CareerTrackAffinity] = Field(default_factory=list)

    # --- Optional Job metadata ---
    location: str | None = None
    remote_status: str | None = None
    time_commitment: str | None = None
    compensation: str | None = None
    deadline: str | None = None
    apply_url: str | None = None

    # --- Contact (never fabricated ?" populated only from real data) ---
    contact_name: str | None = None
    contact_email: str | None = None
