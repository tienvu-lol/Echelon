from fastapi import APIRouter, Query, Depends, HTTPException
from app.config import Settings, get_settings
from app.schemas.requests import SwipeRequest
from app.schemas.responses import SwipeResponse
from app.models.swipe import Swipe, SavedOpportunity

router = APIRouter(prefix="/api", tags=["swipes"])


@router.post("/swipes", response_model=SwipeResponse)
async def record_swipe(
    request: SwipeRequest,
    settings: Settings = Depends(get_settings),
):
    """Record a swipe (left/right) on an opportunity.

    Persists the swipe to Databricks.
    Right swipes also save the opportunity.
    """
    # TODO: Persist to Databricks
    swipe = Swipe(
        student_id=request.student_id,
        opportunity_id=request.opportunity_id,
        direction=request.direction,
    )
    return SwipeResponse(
        id=swipe.id,
        student_id=swipe.student_id,
        opportunity_id=swipe.opportunity_id,
        direction=swipe.direction,
        created_at=swipe.created_at,
    )


@router.get("/saved")
async def get_saved_opportunities(
    student_id: str = Query(..., description="Student ID"),
    settings: Settings = Depends(get_settings),
):
    """Get all saved (right-swiped) opportunities for a student."""
    # TODO: Query Databricks
    return {"student_id": student_id, "opportunities": []}


@router.post("/saved/{opportunity_id}")
async def save_opportunity(
    opportunity_id: str,
    student_id: str = Query(..., description="Student ID"),
    settings: Settings = Depends(get_settings),
):
    """Explicitly save an opportunity (outside of swiping)."""
    # TODO: Persist to Databricks
    saved = SavedOpportunity(
        student_id=student_id,
        opportunity_id=opportunity_id,
    )
    return saved
