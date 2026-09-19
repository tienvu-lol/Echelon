"""Health-check route."""

from fastapi import APIRouter
from pydantic import BaseModel


class HealthResponse(BaseModel):
    status: str


router = APIRouter()


@router.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    """Return a simple liveness signal."""
    return HealthResponse(status="ok")

