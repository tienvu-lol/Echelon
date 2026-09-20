"""Unit tests for the Eligibility Engine.

Pure deterministic logic tests covering class years, majors, school restrictions,
and explanatory notes.
"""

import pytest

from app.models.opportunity import Opportunity
from app.models.student import StudentProfile
from app.services.eligibility_engine import (
    ELIGIBLE,
    INELIGIBLE,
    UNKNOWN,
    evaluate_eligibility,
)


def _make_opp(**overrides) -> Opportunity:
    defaults = dict(
        id="opp-test-1",
        title="Software Engineering Intern",
        organization="VT Innovation Labs",
        opportunity_type="internship",
        description="Software development on campus.",
        source_url="https://vt.edu/opp/1",
    )
    return Opportunity(**{**defaults, **overrides})


class TestClassYearEligibility:
    def test_no_class_year_restriction_is_eligible(self):
        profile = StudentProfile(class_year="Freshman")
        opp = _make_opp(class_years=[])
        status, notes = evaluate_eligibility(profile, opp)
        assert status == ELIGIBLE
        assert "meets all known eligibility criteria" in notes[0]

    def test_matching_class_year_is_eligible(self):
        profile = StudentProfile(class_year="Junior")
        opp = _make_opp(class_years=["Junior", "Senior"])
        status, notes = evaluate_eligibility(profile, opp)
        assert status == ELIGIBLE

    def test_mismatched_class_year_is_ineligible(self):
        profile = StudentProfile(class_year="Freshman")
        opp = _make_opp(class_years=["Junior", "Senior"])
        status, notes = evaluate_eligibility(profile, opp)
        assert status == INELIGIBLE
        assert any("Requires class year in" in note for note in notes)

    def test_unknown_student_class_year_returns_unknown(self):
        profile = StudentProfile(class_year=None)
        opp = _make_opp(class_years=["Junior", "Senior"])
        status, notes = evaluate_eligibility(profile, opp)
        assert status == UNKNOWN
        assert any("class year is unknown" in note for note in notes)


class TestMajorEligibility:
    def test_no_major_restriction_is_eligible(self):
        profile = StudentProfile(major="History")
        opp = _make_opp(majors=[])
        status, notes = evaluate_eligibility(profile, opp)
        assert status == ELIGIBLE

    def test_exact_major_match_is_eligible(self):
        profile = StudentProfile(major="Computer Science")
        opp = _make_opp(majors=["Computer Science", "Computer Engineering"])
        status, notes = evaluate_eligibility(profile, opp)
        assert status == ELIGIBLE

    def test_substring_major_match_is_eligible(self):
        profile = StudentProfile(major="Computer Science")
        opp = _make_opp(majors=["Computer Science and Software Engineering"])
        status, notes = evaluate_eligibility(profile, opp)
        assert status == ELIGIBLE

    def test_reverse_substring_major_match_is_eligible(self):
        profile = StudentProfile(major="Computer Science and Applications")
        opp = _make_opp(majors=["Computer Science"])
        status, notes = evaluate_eligibility(profile, opp)
        assert status == ELIGIBLE

    def test_case_insensitive_major_match_is_eligible(self):
        profile = StudentProfile(major="data science")
        opp = _make_opp(majors=["Data Science"])
        status, notes = evaluate_eligibility(profile, opp)
        assert status == ELIGIBLE

    def test_mismatched_major_is_ineligible(self):
        profile = StudentProfile(major="Philosophy")
        opp = _make_opp(majors=["Computer Science", "Electrical Engineering"])
        status, notes = evaluate_eligibility(profile, opp)
        assert status == INELIGIBLE
        assert any("Requires major in" in note for note in notes)


class TestSchoolRestrictionEligibility:
    @pytest.mark.parametrize("alias", ["Virginia Tech", "VT", "VPI", "Virginia Polytechnic Institute"])
    def test_virginia_tech_aliases_match(self, alias):
        profile = StudentProfile()
        opp = _make_opp(school_restrictions=[alias])
        status, notes = evaluate_eligibility(profile, opp)
        assert status == ELIGIBLE

    def test_non_vt_school_restriction_is_ineligible(self):
        profile = StudentProfile()
        opp = _make_opp(school_restrictions=["University of Virginia", "MIT"])
        status, notes = evaluate_eligibility(profile, opp)
        assert status == INELIGIBLE
        assert any("restricted to specific schools" in note for note in notes)


class TestCombinedEligibilityCriteria:
    def test_all_matching_criteria_returns_eligible(self):
        profile = StudentProfile(major="Computer Science", class_year="Junior")
        opp = _make_opp(
            class_years=["Junior", "Senior"],
            majors=["Computer Science"],
            school_restrictions=["Virginia Tech"],
        )
        status, notes = evaluate_eligibility(profile, opp)
        assert status == ELIGIBLE

    def test_single_failing_criterion_marks_ineligible(self):
        profile = StudentProfile(major="Computer Science", class_year="Freshman")
        opp = _make_opp(
            class_years=["Junior", "Senior"],
            majors=["Computer Science"],
            school_restrictions=["Virginia Tech"],
        )
        status, notes = evaluate_eligibility(profile, opp)
        assert status == INELIGIBLE

