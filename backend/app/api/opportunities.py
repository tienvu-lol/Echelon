from fastapi import APIRouter, Depends, HTTPException, Query

from app.api.deps import get_current_user
from app.models.recommendation import RecommendationsResponse
from app.services.recommendation_service import RecommendationServiceError
from app.services.recommendation_service import (
    get_recommendations as fetch_recommendations,
)

router = APIRouter(prefix="/api", tags=["opportunities"])


@router.get("/opportunities/recommendations", response_model=RecommendationsResponse)
async def get_recommendations(
    limit: int = Query(
        10, ge=1, le=50, description="Maximum number of recommendations"
    ),
    current_user: dict = Depends(get_current_user),
):
    """Get personalized opportunity recommendations for a student.

    Pipeline:
    1. Load student profile and career preferences from Databricks
    2. Filter via Eligibility Engine
    3. Heuristic retrieval (skills/tracks overlap)
    4. Rerank top candidates via Gemini
    5. Return opportunity cards with explanations
    """
    try:
        uid = current_user.get("uid")
        # Pass uid from auth instead of arbitrary query param
        response = fetch_recommendations(uid, limit)
        return response
    except RecommendationServiceError as e:
        raise HTTPException(
            status_code=400,
            detail=str(e),
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Internal Server Error: {e!s}",
        )
