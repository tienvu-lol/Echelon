"""Unit tests for domain models.

These tests are purely structural — no routes, no services, no providers.
They verify field presence, types, defaults, list isolation, and JSON round-trips.
"""

import pytest

from app.models.opportunity import Opportunity
from app.models.student import StudentProfile


# ===========================================================================
# Helpers
# ===========================================================================

REQUIRED_OPPORTUNITY_FIELDS = dict(
    id="opp-001",
    title="Research Assistant",
    organization="VT CS Department",
    opportunity_type="research",
    description="Work on ML research.",
    source_url="https://example.vt.edu/opp/001",
)


def make_opportunity(**overrides) -> Opportunity:
    kwargs = {**REQUIRED_OPPORTUNITY_FIELDS, **overrides}
    return Opportunity(**kwargs)


# ===========================================================================
# StudentProfile — required / optional fields
# ===========================================================================


class TestStudentProfileFields:
    def test_all_fields_optional_by_default(self):
        """StudentProfile can be instantiated with no arguments."""
        profile = StudentProfile()
        assert profile.major is None
        assert profile.class_year is None
        assert profile.bio is None

    def test_scalar_fields_accept_values(self):
        profile = StudentProfile(major="Computer Science", class_year="Sophomore", bio="I love AI")
        assert profile.major == "Computer Science"
        assert profile.class_year == "Sophomore"
        assert profile.bio == "I love AI"

    def test_list_fields_default_to_empty(self):
        profile = StudentProfile()
        assert profile.skills == []
        assert profile.interests == []
        assert profile.coursework == []
        assert profile.experience == []

    def test_list_fields_accept_values(self):
        profile = StudentProfile(
            skills=["Python", "Java"],
            interests=["AI", "Cybersecurity"],
            coursework=["Data Structures"],
            experience=["SWE Intern @ Acme"],
        )
        assert profile.skills == ["Python", "Java"]
        assert profile.interests == ["AI", "Cybersecurity"]
        assert profile.coursework == ["Data Structures"]
        assert profile.experience == ["SWE Intern @ Acme"]


# ===========================================================================
# StudentProfile — list default isolation
# ===========================================================================


class TestStudentProfileListIsolation:
    def test_skills_lists_are_independent(self):
        a = StudentProfile()
        b = StudentProfile()
        a.skills.append("Python")
        assert b.skills == [], "Mutating one instance must not affect another"

    def test_interests_lists_are_independent(self):
        a = StudentProfile()
        b = StudentProfile()
        a.interests.append("AI")
        assert b.interests == []

    def test_coursework_lists_are_independent(self):
        a = StudentProfile()
        b = StudentProfile()
        a.coursework.append("OS")
        assert b.coursework == []

    def test_experience_lists_are_independent(self):
        a = StudentProfile()
        b = StudentProfile()
        a.experience.append("Internship")
        assert b.experience == []


# ===========================================================================
# StudentProfile — JSON serialisation
# ===========================================================================


class TestStudentProfileJSON:
    def test_round_trip_empty(self):
        profile = StudentProfile()
        data = profile.model_dump()
        restored = StudentProfile(**data)
        assert restored == profile

    def test_round_trip_populated(self):
        profile = StudentProfile(
            major="CS",
            class_year="Junior",
            skills=["Python"],
            interests=["ML"],
        )
        json_str = profile.model_dump_json()
        restored = StudentProfile.model_validate_json(json_str)
        assert restored == profile

    def test_json_keys_match_spec(self):
        keys = set(StudentProfile().model_dump().keys())
        expected = {"major", "class_year", "bio", "skills", "interests", "coursework", "experience"}
        assert keys == expected


# ===========================================================================
# Opportunity — required fields
# ===========================================================================


class TestOpportunityRequiredFields:
    def test_required_fields_present(self):
        opp = make_opportunity()
        assert opp.id == "opp-001"
        assert opp.title == "Research Assistant"
        assert opp.organization == "VT CS Department"
        assert opp.opportunity_type == "research"
        assert opp.description == "Work on ML research."
        assert opp.source_url == "https://example.vt.edu/opp/001"

    @pytest.mark.parametrize("missing_field", list(REQUIRED_OPPORTUNITY_FIELDS.keys()))
    def test_missing_required_field_raises(self, missing_field):
        from pydantic import ValidationError

        kwargs = {k: v for k, v in REQUIRED_OPPORTUNITY_FIELDS.items() if k != missing_field}
        with pytest.raises(ValidationError):
            Opportunity(**kwargs)


# ===========================================================================
# Opportunity — optional / default fields
# ===========================================================================


class TestOpportunityOptionalFields:
    def test_optional_scalars_default_to_none(self):
        opp = make_opportunity()
        assert opp.location is None
        assert opp.time_commitment is None
        assert opp.compensation is None
        assert opp.deadline is None
        assert opp.apply_url is None
        assert opp.contact_name is None
        assert opp.contact_email is None

    def test_optional_lists_default_to_empty(self):
        opp = make_opportunity()
        assert opp.skills == []
        assert opp.interests == []
        assert opp.eligibility == []
        assert opp.majors == []
        assert opp.class_years == []

    def test_optional_fields_accept_values(self):
        opp = make_opportunity(
            location="Blacksburg, VA",
            time_commitment="10 hrs/week",
            compensation="Unpaid",
            deadline="2026-12-01",
            apply_url="https://example.vt.edu/apply/001",
            contact_name="Dr. Smith",
            contact_email="smith@vt.edu",
        )
        assert opp.location == "Blacksburg, VA"
        assert opp.contact_email == "smith@vt.edu"


# ===========================================================================
# Opportunity — list default isolation
# ===========================================================================


class TestOpportunityListIsolation:
    @pytest.mark.parametrize("field", ["skills", "interests", "eligibility", "majors", "class_years"])
    def test_list_field_is_independent(self, field):
        a = make_opportunity()
        b = make_opportunity()
        getattr(a, field).append("sentinel")
        assert getattr(b, field) == [], f"Field '{field}' is not isolated between instances"


# ===========================================================================
# Opportunity — JSON serialisation
# ===========================================================================


class TestOpportunityJSON:
    def test_round_trip(self):
        opp = make_opportunity(skills=["Python"], location="Blacksburg, VA")
        json_str = opp.model_dump_json()
        restored = Opportunity.model_validate_json(json_str)
        assert restored == opp

    def test_json_keys_include_required(self):
        keys = set(make_opportunity().model_dump().keys())
        for field in REQUIRED_OPPORTUNITY_FIELDS:
            assert field in keys

    def test_json_keys_include_all_optional(self):
        keys = set(make_opportunity().model_dump().keys())
        optional = {
            "skills", "interests", "eligibility", "majors", "class_years",
            "location", "time_commitment", "compensation", "deadline",
            "apply_url", "contact_name", "contact_email",
        }
        assert optional.issubset(keys)

