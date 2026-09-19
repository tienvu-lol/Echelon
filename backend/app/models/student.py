from pydantic import BaseModel, Field

class ParsedProfile(BaseModel):
    major: str | None = Field(default=None, description="The student's major")
    year: str | None = Field(default=None, description="The student's current academic year, e.g., Freshman, Sophomore")
    skills: list[str] = Field(default_factory=list, description="List of technical and soft skills")
    interests: list[str] = Field(default_factory=list, description="List of academic and career interests")
    coursework: list[str] = Field(default_factory=list, description="List of relevant coursework")
    experience: list[str] = Field(default_factory=list, description="List of past jobs, internships, or research")
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

