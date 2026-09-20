"""Recommendation models.

Models for user preferences, inferred traits, and the structured response
sent to the frontend when recommending opportunities.
"""

from typing import Optional
from pydantic import BaseModel, Field

from app.models.opportunity import Opportunity, CareerTrackAffinity


class CareerPreferences(BaseModel):
    """Represents a student's career preferences, both explicit and inferred.
    
    This is populated either explicitly by the student or inferred via the
    Echelon conversational agent.
    """
    
    # Inferred/explicit affinities
    career_tracks: list[CareerTrackAffinity] = Field(default_factory=list)
    
    # Explicit preferences
    preferred_role_types: list[str] = Field(default_factory=list)
    preferred_locations: list[str] = Field(default_factory=list)
    remote_preference: Optional[str] = None
    industries_of_interest: list[str] = Field(default_factory=list)
    technologies_to_use: list[str] = Field(default_factory=list)
    technologies_to_learn: list[str] = Field(default_factory=list)
    
    research_vs_industry: Optional[str] = None
    startup_vs_large_company: Optional[str] = None
    career_goals: Optional[str] = None
    other_preferences: Optional[str] = None


class RecommendationResponseItem(BaseModel):
    """A single recommended opportunity with its explanation."""
    
    opportunity: Opportunity
    score: int
    match_reason: str
    matched_traits: list[str] = Field(default_factory=list)
    gaps: list[str] = Field(default_factory=list)
    career_track_fit: list[str] = Field(default_factory=list)
    eligibility_status: str
    eligibility_notes: list[str] = Field(default_factory=list)


class RecommendationsResponse(BaseModel):
    """The full payload returned by GET /api/opportunities/recommendations."""
    
    student_id: str
    opportunities: list[RecommendationResponseItem]

