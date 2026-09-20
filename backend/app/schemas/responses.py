from datetime import date, datetime

from pydantic import BaseModel


class HealthResponse(BaseModel):
    status: str


class ServiceTestResponse(BaseModel):
    service: str
    status: str
    message: str
    details: dict | None = None


class OpportunityCard(BaseModel):
    id: str
    title: str
    organization: str
    opportunity_type: str
    description: str
    skills: list[str] = []
    location: str | None = None
    paid: bool | None = None
    deadline: date | None = None
    apply_url: str | None = None
    explanation: str | None = None


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
    detail: str | None = None
