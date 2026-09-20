"""StudentProfile domain model.

Provider-independent.  No imports from Gemini, Databricks, or Firebase.
"""

from pydantic import BaseModel, Field


class StudentProfile(BaseModel):
    """Represents a parsed student profile.

    All list fields use ``Field(default_factory=list)`` so each instance
    receives its own independent list object.
    """

    major: str | None = Field(default=None, description="The student's major")
    class_year: str | None = Field(
        default=None,
        description="The student's current academic year, e.g., Freshman, Sophomore",
    )
    bio: str | None = Field(default=None, description="Optional free-text bio.")
    skills: list[str] = Field(
        default_factory=list, description="List of technical and soft skills"
    )
    interests: list[str] = Field(
        default_factory=list, description="List of academic and career interests"
    )
    coursework: list[str] = Field(
        default_factory=list, description="List of relevant coursework"
    )
    experience: list[str] = Field(
        default_factory=list, description="List of past jobs, internships, or research"
    )
