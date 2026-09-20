"""Candidate Retrieval System.

Pulls active opportunities and applies a heuristic scoring to find the top candidates
for Gemini to rerank.
"""

from app.models.opportunity import Opportunity
from app.models.recommendation import CareerPreferences
from app.models.student import StudentProfile
from app.services import databricks_service
from app.services.eligibility_engine import INELIGIBLE, evaluate_eligibility


def get_top_candidates(
    profile: StudentProfile,
    preferences: CareerPreferences,
    all_opportunities: list[Opportunity] = None,
    limit: int = 40,
) -> list[Opportunity]:
    """Retrieves and scores top candidates based on deterministic heuristics."""

    if all_opportunities is None:
        all_opportunities = databricks_service.get_active_opportunities()

    scored_candidates: list[tuple[float, Opportunity]] = []

    # Heuristic weights
    TRACK_WEIGHT = 5.0
    SKILL_WEIGHT = 1.0
    INTEREST_WEIGHT = 0.5

    student_skills = set([s.lower() for s in profile.skills])
    student_interests = set([i.lower() for i in profile.interests])

    # Map preferred tracks
    preferred_tracks = set([ct.track for ct in preferences.career_tracks])

    for opp in all_opportunities:
        # 1. Hard Filter via Eligibility Engine
        status, notes = evaluate_eligibility(profile, opp)
        if status == INELIGIBLE:
            continue

        # 2. Heuristic Scoring
        score = 0.0

        # Track Overlap
        opp_tracks = [ct.track for ct in opp.career_tracks]
        for t in opp_tracks:
            if t in preferred_tracks:
                # Add score proportional to the opportunity's affinity weight if available
                # (Assuming weights are 0-1)
                affinity = next(
                    (ct.weight for ct in opp.career_tracks if ct.track == t), 0.5
                )
                score += TRACK_WEIGHT * affinity

        # Skills Overlap
        opp_skills = set([s.lower() for s in opp.skills])
        overlap_skills = student_skills.intersection(opp_skills)
        score += len(overlap_skills) * SKILL_WEIGHT

        # Interests Overlap
        opp_interests = set([i.lower() for i in opp.interests])
        overlap_interests = student_interests.intersection(opp_interests)
        score += len(overlap_interests) * INTEREST_WEIGHT

        # Give a slight boost if eligibility is strictly ELIGIBLE rather than UNKNOWN
        if status == "ELIGIBLE":
            score += 1.0

        scored_candidates.append((score, opp))

    # Sort by score descending
    scored_candidates.sort(key=lambda x: x[0], reverse=True)

    # Return top N candidates
    return [opp for score, opp in scored_candidates[:limit]]
