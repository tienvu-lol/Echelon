"""Master orchestrator for the recommendation engine."""

import logging
from typing import List, Optional

from app.models.recommendation import RecommendationsResponse, RecommendationResponseItem, CareerPreferences
from app.models.student import StudentProfile
from app.services import databricks_service, gemini_service, candidate_retrieval
from app.services.eligibility_engine import evaluate_eligibility

logger = logging.getLogger(__name__)

class RecommendationServiceError(Exception):
    pass

def get_recommendations(uid: str, limit: int = 10) -> RecommendationsResponse:
    """End-to-end recommendation workflow."""
    
    # 1. Load context
    profile = databricks_service.get_student_profile(uid)
    if not profile:
        raise RecommendationServiceError("Student profile not found. Please complete onboarding first.")
        
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
    reranked_items = gemini_service.rerank_opportunities(profile, preferences, candidates)
    
    # 4. Attach eligibility notes explicitly
    for item in reranked_items:
        status, notes = evaluate_eligibility(profile, item.opportunity)
        item.eligibility_status = status
        item.eligibility_notes = notes
        
    # Apply hard limit after reranking
    final_items = reranked_items[:limit]
    
    return RecommendationsResponse(
        student_id=uid,
        opportunities=final_items
    )

