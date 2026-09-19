"""Opportunity domain model.

Provider-independent.  No imports from Gemini, Databricks, or Firebase.
"""

from pydantic import BaseModel, Field


class Opportunity(BaseModel):
    """Represents a single campus opportunity (research, job, club, etc.).

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

    # --- Filterable lists ---
    skills: list[str] = Field(default_factory=list)
    interests: list[str] = Field(default_factory=list)
    eligibility: list[str] = Field(default_factory=list)
    majors: list[str] = Field(default_factory=list)
    class_years: list[str] = Field(default_factory=list)

    # --- Optional metadata ---
    location: str | None = None
    time_commitment: str | None = None
    compensation: str | None = None
    deadline: str | None = None
    apply_url: str | None = None

    # --- Contact (never fabricated — populated only from real data) ---
    contact_name: str | None = None
    contact_email: str | None = None

