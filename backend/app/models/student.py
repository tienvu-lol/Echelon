from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional
import uuid

class StudentProfile(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    major: str
    graduation_year: int
    skills: list[str] = Field(default_factory=list)
    interests: list[str] = Field(default_factory=list)
    coursework: list[str] = Field(default_factory=list)
    experience: list[str] = Field(default_factory=list)
    bio: Optional[str] = None
    profile_text: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
