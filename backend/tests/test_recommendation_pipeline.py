"""End-to-end service and API tests for the recommendation orchestration pipeline."""

from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient

from app.api.deps import get_current_user
from app.main import app
from app.models.opportunity import CareerTrackAffinity, Opportunity
from app.models.recommendation import (
    CareerPreferences,
    RecommendationResponseItem,
    RecommendationsResponse,
)
from app.models.student import StudentProfile
from app.services.recommendation_service import (
    RecommendationServiceError,
    get_recommendations,
)

client = TestClient(app)


def _make_sample_student(uid: str = "vt-student-1") -> StudentProfile:
    return StudentProfile(
        major="Computer Science",
        class_year="Junior",
        bio="Passionate about systems and distributed computing.",
        skills=["Python", "C++", "Linux", "Git"],
        interests=["Software Systems", "Open Source"],
        coursework=["Data Structures", "Operating Systems"],
        experience=["Undergraduate Research Assistant"],
    )


def _make_sample_prefs() -> CareerPreferences:
    return CareerPreferences(
        career_tracks=[CareerTrackAffinity(track="software_engineering", weight=0.9)],
        preferred_role_types=["internship"],
    )


def _make_sample_opp(opp_id: str, title: str, active: bool = True) -> Opportunity:
    return Opportunity(
        id=opp_id,
        title=title,
        organization="Virginia Tech CS",
        opportunity_type="internship",
        description=f"Great opportunity for {title}",
        source_url="https://cs.vt.edu",
        apply_url="https://cs.vt.edu/apply",
        active=active,
        skills=["Python", "Linux"],
        interests=["Software Systems"],
        career_tracks=[CareerTrackAffinity(track="software_engineering", weight=1.0)],
    )


class TestRecommendationServiceOrchestration:
    def test_full_pipeline_success(self):
        """Recommendation workflow correctly chains Databricks, heuristics, and Gemini."""
        student = _make_sample_student("user-abc")
        prefs = _make_sample_prefs()
        opp1 = _make_sample_opp("opp-1", "Systems Software Intern")
        opp2 = _make_sample_opp("opp-2", "Firmware Intern")

        mock_reranked = [
            RecommendationResponseItem(
                opportunity=opp1,
                score=95,
                match_reason="Matches your CS major, Linux skills, and systems interest.",
                eligibility_status="ELIGIBLE",
            )
        ]

        with (
            patch("app.services.databricks_service.get_student_profile", return_value=student),
            patch("app.services.databricks_service.get_career_preferences", return_value=prefs),
            patch(
                "app.services.databricks_service.get_active_opportunities",
                return_value=[opp1, opp2],
            ),
            patch("app.services.gemini_service.rerank_opportunities", return_value=mock_reranked),
        ):
            resp = get_recommendations("user-abc", limit=5)

        assert isinstance(resp, RecommendationsResponse)
        assert resp.student_id == "user-abc"
        assert len(resp.opportunities) == 1
        assert resp.opportunities[0].opportunity.id == "opp-1"
        assert resp.opportunities[0].score == 95
        assert resp.opportunities[0].eligibility_status in ("ELIGIBLE", "UNKNOWN")

    def test_missing_student_profile_raises(self):
        """When student profile does not exist in Databricks, raises RecommendationServiceError."""
        with patch("app.services.databricks_service.get_student_profile", return_value=None):
            with pytest.raises(RecommendationServiceError) as exc:
                get_recommendations("unknown-user")
            assert "Student profile not found" in str(exc.value)

    def test_missing_career_preferences_uses_defaults(self):
        """Missing career preferences smoothly falls back to empty defaults without error."""
        student = _make_sample_student("user-noprefs")
        opp = _make_sample_opp("opp-10", "Web Development Assistant")

        with (
            patch("app.services.databricks_service.get_student_profile", return_value=student),
            patch("app.services.databricks_service.get_career_preferences", return_value=None),
            patch(
                "app.services.databricks_service.get_active_opportunities",
                return_value=[opp],
            ),
            patch(
                "app.services.gemini_service.rerank_opportunities",
                return_value=[
                    RecommendationResponseItem(
                        opportunity=opp,
                        score=80,
                        match_reason="Good skill alignment.",
                        eligibility_status="ELIGIBLE",
                    )
                ],
            ),
        ):
            resp = get_recommendations("user-noprefs", limit=5)

        assert resp.student_id == "user-noprefs"
        assert len(resp.opportunities) == 1

    def test_no_active_candidates_returns_empty_list(self):
        """When no active opportunities exist, returns empty recommendation list immediately."""
        student = _make_sample_student("user-empty")
        prefs = _make_sample_prefs()

        with (
            patch("app.services.databricks_service.get_student_profile", return_value=student),
            patch("app.services.databricks_service.get_career_preferences", return_value=prefs),
            patch("app.services.databricks_service.get_active_opportunities", return_value=[]),
            patch("app.services.gemini_service.rerank_opportunities") as mock_gemini,
        ):
            resp = get_recommendations("user-empty", limit=10)

        assert resp.student_id == "user-empty"
        assert resp.opportunities == []
        mock_gemini.assert_not_called()


class TestRecommendationAPIRoute:
    def test_get_recommendations_endpoint(self):
        """GET /api/opportunities/recommendations derives UID from auth token."""
        student = _make_sample_student("firebase-uid-999")
        opp = _make_sample_opp("opp-endpoint", "AI Research Co-op")

        mock_user = {"uid": "firebase-uid-999", "email": "student@vt.edu"}
        app.dependency_overrides[get_current_user] = lambda: mock_user

        try:
            with (
                patch(
                    "app.services.databricks_service.get_student_profile",
                    return_value=student,
                ),
                patch(
                    "app.services.databricks_service.get_career_preferences",
                    return_value=CareerPreferences(),
                ),
                patch(
                    "app.services.databricks_service.get_active_opportunities",
                    return_value=[opp],
                ),
                patch(
                    "app.services.gemini_service.rerank_opportunities",
                    return_value=[
                        RecommendationResponseItem(
                            opportunity=opp,
                            score=92,
                            match_reason="Direct match for AI interest.",
                            eligibility_status="ELIGIBLE",
                        )
                    ],
                ),
            ):

                response = client.get(
                    "/api/opportunities/recommendations?limit=10",
                    headers={"Authorization": "Bearer mock-firebase-token"},
                )

            assert response.status_code == 200
            data = response.json()
            assert data["student_id"] == "firebase-uid-999"
            assert len(data["opportunities"]) == 1
            assert data["opportunities"][0]["opportunity"]["id"] == "opp-endpoint"
            assert data["opportunities"][0]["score"] == 92.0
            assert "match_reason" in data["opportunities"][0]
        finally:
            app.dependency_overrides.clear()
