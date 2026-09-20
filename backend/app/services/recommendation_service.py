"""Master orchestrator for the recommendation engine."""

import logging

from app.models.recommendation import (
    CareerPreferences,
    RecommendationsResponse,
)
from app.services import candidate_retrieval, databricks_service, gemini_service
from app.services.eligibility_engine import evaluate_eligibility

logger = logging.getLogger(__name__)


class RecommendationServiceError(Exception):
    pass


class StudentProfileNotFoundError(RecommendationServiceError):
    pass


def get_recommendations(uid: str, limit: int = 10) -> RecommendationsResponse:
    """End-to-end recommendation workflow."""

    # 1. Load context
    profile = databricks_service.get_student_profile(uid)
    if not profile:
        raise StudentProfileNotFoundError(
            "Student profile not found. Please complete onboarding first."
        )

    preferences = databricks_service.get_career_preferences(uid)
    if not preferences:
        # Default empty preferences if none exist yet
        preferences = CareerPreferences()

    # 2. Heuristic Retrieval (fast pass)
    # We fetch more than we need so Gemini has room to rerank
    candidates = candidate_retrieval.get_top_candidates(profile, preferences, limit=30)

    if not candidates:
        return RecommendationsResponse(student_id=uid, opportunities=[])

    # 3. LLM Reranking (slow pass)
    reranked_items = gemini_service.rerank_opportunities(
        profile, preferences, candidates
    )

    # 4. Attach eligibility notes explicitly
    for item in reranked_items:
        status, notes = evaluate_eligibility(profile, item.opportunity)
        item.eligibility_status = status
        item.eligibility_notes = notes

    # Apply hard limit after reranking
    final_items = reranked_items[:limit]

    return RecommendationsResponse(student_id=uid, opportunities=final_items)
