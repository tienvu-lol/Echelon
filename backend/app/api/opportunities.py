from fastapi import APIRouter, Query, Depends, HTTPException
from typing import Optional
from app.config import Settings, get_settings
from app.schemas.responses import RecommendationsResponse

router = APIRouter(prefix="/api", tags=["opportunities"])


@router.get("/opportunities/recommendations", response_model=RecommendationsResponse)
async def get_recommendations(
    student_id: str = Query(..., description="Student ID to get recommendations for"),
    limit: int = Query(10, ge=1, le=50, description="Maximum number of recommendations"),
    settings: Settings = Depends(get_settings),
):
    """Get personalized opportunity recommendations for a student.

    Pipeline (not yet implemented):
    1. Load student profile from Databricks
    2. Generate embedding from profile_text via Gemini
    3. Query Databricks AI Search with embedding
    4. Apply metadata filters
    5. Generate explanations via Gemini
    6. Return opportunity cards
    """
    raise HTTPException(
        status_code=501,
        detail="Recommendation pipeline not yet implemented.",
    )
