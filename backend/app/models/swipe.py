from pydantic import BaseModel, Field
from datetime import datetime
from typing import Literal
import uuid

class Swipe(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    student_id: str
    opportunity_id: str
    direction: Literal["left", "right"]
    created_at: datetime = Field(default_factory=datetime.utcnow)

class SavedOpportunity(BaseModel):
    student_id: str
    opportunity_id: str
    created_at: datetime = Field(default_factory=datetime.utcnow)
