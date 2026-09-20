from datetime import datetime

from pydantic import BaseModel

from app.models.recommendation import RecommendationsResponse


class HealthResponse(BaseModel):
    status: str


class ServiceTestResponse(BaseModel):
    service: str
    status: str
    message: str
    details: dict | None = None


class SwipeResponse(BaseModel):
    id: str
    student_id: str
    opportunity_id: str
    direction: str
    created_at: datetime


class ErrorResponse(BaseModel):
    error: str
    detail: str | None = None


from app.models.opportunity import Opportunity

class SavedOpportunitiesResponse(BaseModel):
    student_id: str
    opportunities: list[Opportunity]


class SavedOpportunityResponse(BaseModel):
    student_id: str
    opportunity_id: str


class StatusResponse(BaseModel):
    status: str

__all__ = [
    "HealthResponse",
    "ServiceTestResponse",
    "SwipeResponse",
    "ErrorResponse",
    "RecommendationsResponse",
    "SavedOpportunitiesResponse",
    "SavedOpportunityResponse",
    "StatusResponse",
]
