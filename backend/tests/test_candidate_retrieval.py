"""Unit tests for the Candidate Retrieval System.

Tests heuristic scoring, track weighting, skill and interest overlaps, eligibility filtering,
and Databricks fallback fetching.
"""

from unittest.mock import patch

import pytest

from app.models.opportunity import CareerTrackAffinity, Opportunity
from app.models.recommendation import CareerPreferences
from app.models.student import StudentProfile
from app.services.candidate_retrieval import get_top_candidates


def _make_opp(
    opp_id: str,
    title: str = "Software Role",
    skills: list[str] | None = None,
    interests: list[str] | None = None,
    tracks: list[CareerTrackAffinity] | None = None,
    majors: list[str] | None = None,
    class_years: list[str] | None = None,
) -> Opportunity:
    return Opportunity(
        id=opp_id,
        title=title,
        organization="VT Engineering",
        opportunity_type="internship",
        description=f"Opportunity {opp_id}",
        source_url="https://vt.edu",
        skills=skills or [],
        interests=interests or [],
        career_tracks=tracks or [],
        majors=majors or [],
        class_years=class_years or [],
    )


class TestCandidateRetrieval:
    def test_ineligible_opportunities_are_filtered_out(self):
        profile = StudentProfile(major="Computer Science", class_year="Freshman")
        prefs = CareerPreferences()

        opp_eligible = _make_opp("opp-eligible", majors=["Computer Science"])
        opp_ineligible = _make_opp("opp-ineligible", class_years=["Senior"])  # Mismatch

        candidates = get_top_candidates(
            profile=profile,
            preferences=prefs,
            all_opportunities=[opp_eligible, opp_ineligible],
        )

        assert len(candidates) == 1
        assert candidates[0].id == "opp-eligible"

    def test_heuristic_scoring_prefers_track_and_skill_matches(self):
        profile = StudentProfile(
            major="Computer Science",
            skills=["Python", "C++", "SQL"],
            interests=["AI", "Distributed Systems"],
        )
        prefs = CareerPreferences(
            career_tracks=[CareerTrackAffinity(track="software_engineering", weight=1.0)],
        )

        # opp_strong: matching career track (5.0*1.0) + 2 matching skills (2.0) + 1 interest (0.5) + eligible (1.0) = 8.5
        opp_strong = _make_opp(
            "opp-strong",
            skills=["Python", "C++"],
            interests=["AI"],
            tracks=[CareerTrackAffinity(track="software_engineering", weight=1.0)],
        )

        # opp_weak: 0 matching tracks, 1 matching skill (1.0) + eligible (1.0) = 2.0
        opp_weak = _make_opp(
            "opp-weak",
            skills=["SQL"],
            interests=["Design"],
            tracks=[CareerTrackAffinity(track="product_management", weight=1.0)],
        )

        candidates = get_top_candidates(
            profile=profile,
            preferences=prefs,
            all_opportunities=[opp_weak, opp_strong],
        )

        assert len(candidates) == 2
        assert candidates[0].id == "opp-strong"
        assert candidates[1].id == "opp-weak"

    def test_limit_truncates_results(self):
        profile = StudentProfile()
        prefs = CareerPreferences()
        opps = [_make_opp(f"opp-{i}") for i in range(10)]

        candidates = get_top_candidates(
            profile=profile,
            preferences=prefs,
            all_opportunities=opps,
            limit=3,
        )

        assert len(candidates) == 3

    def test_retrieves_from_databricks_when_opportunities_none(self):
        profile = StudentProfile()
        prefs = CareerPreferences()
        mock_opps = [_make_opp("db-opp-1"), _make_opp("db-opp-2")]

        with patch(
            "app.services.databricks_service.get_active_opportunities",
            return_value=mock_opps,
        ) as mock_get_active:
            candidates = get_top_candidates(profile=profile, preferences=prefs)

        mock_get_active.assert_called_once()
        assert len(candidates) == 2
        assert candidates[0].id in ("db-opp-1", "db-opp-2")

    def test_filters_expired_opportunities(self):
        profile = StudentProfile()
        prefs = CareerPreferences()

        # Create an expired opp and a future opp
        opp_expired = _make_opp("opp-expired")
        opp_expired.deadline = "2020-01-01"  # way in the past

        opp_future = _make_opp("opp-future")
        opp_future.deadline = "2099-12-31"  # way in the future

        opp_unknown = _make_opp("opp-unknown")
        opp_unknown.deadline = "Rolling" # should not be filtered

        candidates = get_top_candidates(
            profile=profile,
            preferences=prefs,
            all_opportunities=[opp_expired, opp_future, opp_unknown],
        )

        assert len(candidates) == 2
        candidate_ids = {c.id for c in candidates}
        assert "opp-future" in candidate_ids
        assert "opp-unknown" in candidate_ids
        assert "opp-expired" not in candidate_ids

