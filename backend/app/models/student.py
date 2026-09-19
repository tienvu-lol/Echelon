from pydantic import BaseModel, Field

class ParsedProfile(BaseModel):
    major: str | None = Field(default=None, description="The student's major")
    year: str | None = Field(default=None, description="The student's current academic year, e.g., Freshman, Sophomore")
    skills: list[str] = Field(default_factory=list, description="List of technical and soft skills")
    interests: list[str] = Field(default_factory=list, description="List of academic and career interests")
    coursework: list[str] = Field(default_factory=list, description="List of relevant coursework")
    experience: list[str] = Field(default_factory=list, description="List of past jobs, internships, or research")

