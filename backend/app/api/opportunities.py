import logging

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.api.deps import get_current_user
from app.models.recommendation import RecommendationsResponse
from app.services.recommendation_service import (
    RecommendationServiceError,
    StudentProfileNotFoundError,
    get_recommendations as fetch_recommendations,
)

logger = logging.getLogger(__name__)

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
    uid = current_user.get("uid")
    if not uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid user token.",
        )

    try:
        response = fetch_recommendations(uid, limit)
        return response
    except StudentProfileNotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e),
        )
    except RecommendationServiceError as e:
        logger.error("Recommendation service error for uid %s: %s", uid, e, exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate recommendations.",
        )
    except Exception as e:
        logger.error("Unexpected error generating recommendations for uid %s: %s", uid, e, exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error.",
        )
