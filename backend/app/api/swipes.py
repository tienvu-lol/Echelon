from fastapi import APIRouter, Depends, HTTPException, status

from app.api.deps import get_current_user
from app.models.swipe import Swipe
from app.schemas.requests import SwipeRequest
from app.schemas.responses import (
    SavedOpportunitiesResponse,
    SavedOpportunityResponse,
    StatusResponse,
    SwipeResponse,
)
from app.services import databricks_service

router = APIRouter(prefix="/api", tags=["swipes"])


@router.post("/swipes", response_model=SwipeResponse)
async def record_swipe(
    request: SwipeRequest,
    current_user: dict = Depends(get_current_user),
):
    """Record a swipe (left/right) on an opportunity.

    Persists the swipe to Databricks.
    Right swipes also save the opportunity.
    """
    student_id = current_user["uid"]
    if databricks_service.get_opportunity(request.opportunity_id) is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Opportunity not found.",
        )

    swipe = Swipe(
        student_id=student_id,
        opportunity_id=request.opportunity_id,
        direction=request.direction,
    )
    databricks_service.save_swipe(student_id, request.opportunity_id, request.direction)
    if request.direction == "right":
        databricks_service.save_saved_opportunity(student_id, request.opportunity_id)
    else:
        databricks_service.remove_saved_opportunity(student_id, request.opportunity_id)
    return SwipeResponse(
        id=swipe.id,
        student_id=swipe.student_id,
        opportunity_id=swipe.opportunity_id,
        direction=swipe.direction,
        created_at=swipe.created_at,
    )


@router.get("/saved", response_model=SavedOpportunitiesResponse)
async def get_saved_opportunities(
    current_user: dict = Depends(get_current_user),
):
    """Get all saved (right-swiped) opportunities for a student."""
    student_id = current_user["uid"]
    return SavedOpportunitiesResponse(
        student_id=student_id,
        opportunities=databricks_service.get_saved_opportunities(student_id),
    )


@router.post("/saved/{opportunity_id}", response_model=SavedOpportunityResponse)
async def save_opportunity(
    opportunity_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Explicitly save an opportunity (outside of swiping)."""
    student_id = current_user["uid"]
    if databricks_service.get_opportunity(opportunity_id) is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Opportunity not found.")
    databricks_service.save_saved_opportunity(student_id, opportunity_id)
    return {"student_id": student_id, "opportunity_id": opportunity_id}


@router.delete("/saved/{opportunity_id}", response_model=StatusResponse)
async def delete_saved_opportunity(
    opportunity_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Remove a saved opportunity; repeated deletes remain successful."""
    student_id = current_user["uid"]
    if databricks_service.get_opportunity(opportunity_id) is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Opportunity not found.")
    databricks_service.remove_saved_opportunity(student_id, opportunity_id)
    return {"status": "success"}
