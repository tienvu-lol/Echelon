from pydantic import BaseModel
from typing import Optional, Literal

class ProfileParseRequest(BaseModel):
    bio: Optional[str] = None
    interests: list[str] = []

class ProfileCreateRequest(BaseModel):
    major: str
    graduation_year: int
    skills: list[str] = []
    interests: list[str] = []
    coursework: list[str] = []
    experience: list[str] = []
    bio: Optional[str] = None

class SwipeRequest(BaseModel):
    student_id: str
    opportunity_id: str
    direction: Literal["left", "right"]
