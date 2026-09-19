from pydantic import BaseModel, Field
from datetime import datetime, date
from typing import Optional
import uuid

class Opportunity(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    title: str
    organization: str
    opportunity_type: str
    description: str
    skills: list[str] = Field(default_factory=list)
    majors: list[str] = Field(default_factory=list)
    class_years: list[int] = Field(default_factory=list)
    location: Optional[str] = None
    paid: Optional[bool] = None
    deadline: Optional[date] = None
    contact_name: Optional[str] = None
    contact_email: Optional[str] = None
    apply_url: Optional[str] = None
    source_url: Optional[str] = None
    source_name: Optional[str] = None
    search_text: Optional[str] = None
    embedding: Optional[list[float]] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    last_seen_at: datetime = Field(default_factory=datetime.utcnow)
