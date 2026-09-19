"""StudentProfile domain model.

Provider-independent.  No imports from Gemini, Databricks, or Firebase.
"""

from pydantic import BaseModel, Field


class StudentProfile(BaseModel):
    """Represents a parsed student profile.

    All list fields use ``Field(default_factory=list)`` so each instance
    receives its own independent list object.
    """

    major: str | None = None
    class_year: str | None = None
    bio: str | None = None
    skills: list[str] = Field(default_factory=list)
    interests: list[str] = Field(default_factory=list)
    coursework: list[str] = Field(default_factory=list)
    experience: list[str] = Field(default_factory=list)

