import pytest
from pydantic import ValidationError
from app.models.student import StudentProfile
from app.models.opportunity import Opportunity
from app.models.swipe import Swipe, SavedOpportunity


class TestStudentProfile:
    def test_valid_profile(self):
        profile = StudentProfile(
            major="Computer Science",
            graduation_year=2027,
            skills=["Python", "TypeScript"],
            interests=["AI", "Web Development"],
        )
        assert profile.major == "Computer Science"
        assert profile.graduation_year == 2027
        assert len(profile.skills) == 2
        assert profile.id is not None
        assert profile.created_at is not None

    def test_minimal_profile(self):
        profile = StudentProfile(
            major="Engineering",
            graduation_year=2028,
        )
        assert profile.skills == []
        assert profile.bio is None
        assert profile.profile_text is None

    def test_missing_required_fields(self):
        with pytest.raises(ValidationError):
            StudentProfile()


class TestOpportunity:
    def test_valid_opportunity(self):
        opp = Opportunity(
            title="ML Research Assistant",
            organization="VT CS Department",
            opportunity_type="research",
            description="Assist with NLP research",
            skills=["Python", "NLP"],
            majors=["Computer Science"],
            class_years=[2026, 2027],
        )
        assert opp.title == "ML Research Assistant"
        assert opp.embedding is None
        assert opp.paid is None

    def test_missing_required_fields(self):
        with pytest.raises(ValidationError):
            Opportunity()


class TestSwipe:
    def test_valid_swipe(self):
        swipe = Swipe(
            student_id="student-123",
            opportunity_id="opp-456",
            direction="right",
        )
        assert swipe.direction == "right"
        assert swipe.id is not None

    def test_invalid_direction(self):
        with pytest.raises(ValidationError):
            Swipe(
                student_id="student-123",
                opportunity_id="opp-456",
                direction="up",
            )

    def test_saved_opportunity(self):
        saved = SavedOpportunity(
            student_id="student-123",
            opportunity_id="opp-456",
        )
        assert saved.student_id == "student-123"
