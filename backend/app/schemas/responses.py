from pydantic import BaseModel
from typing import Optional
from datetime import datetime, date

class HealthResponse(BaseModel):
    status: str

class ServiceTestResponse(BaseModel):
    service: str
    status: str
    message: str
    details: Optional[dict] = None

class OpportunityCard(BaseModel):
    id: str
    title: str
    organization: str
    opportunity_type: str
    description: str
    skills: list[str] = []
    location: Optional[str] = None
    paid: Optional[bool] = None
    deadline: Optional[date] = None
    apply_url: Optional[str] = None
    explanation: Optional[str] = None

class RecommendationsResponse(BaseModel):
    student_id: str
    opportunities: list[OpportunityCard]

class SwipeResponse(BaseModel):
    id: str
    student_id: str
    opportunity_id: str
    direction: str
    created_at: datetime

class ErrorResponse(BaseModel):
    error: str
    detail: Optional[str] = None
