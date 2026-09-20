from typing import Literal

from pydantic import BaseModel


class ProfileParseRequest(BaseModel):
    bio: str | None = None
    interests: list[str] = []


class ProfileCreateRequest(BaseModel):
    major: str
    graduation_year: int
    skills: list[str] = []
    interests: list[str] = []
    coursework: list[str] = []
    experience: list[str] = []
    bio: str | None = None


class SwipeRequest(BaseModel):
    student_id: str
    opportunity_id: str
    direction: Literal["left", "right"]
