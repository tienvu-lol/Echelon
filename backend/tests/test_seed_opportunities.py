"""Tests for bulk opportunity seed workflow.

Verifies:
- Valid JSON dataset loading and parsing
- Canonical Opportunity validation
- Malformed records fail before any Databricks writes
- Empty dataset handling
- save_opportunities() receives the complete validated collection
"""

import json
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

from app.models.opportunity import Opportunity
from scripts.seed_opportunities import (
    DEFAULT_SEED_FILE,
    SeedValidationError,
    load_and_validate_opportunities,
    seed_opportunities,
)


def test_default_seed_file_exists_and_is_valid():
    """backend/data/opportunities_seed.json must exist and validate."""
    assert DEFAULT_SEED_FILE.exists()
    opportunities = load_and_validate_opportunities(DEFAULT_SEED_FILE)
    assert len(opportunities) >= 1
    gcc_opp = opportunities[0]
    assert gcc_opp.id == "vt-gcc-undergrad-research-grant-2026-27"
    assert gcc_opp.title == "Global Change Center Undergraduate Research Grant 2026-27"
    assert gcc_opp.organization == "Global Change Center at Virginia Tech"
    assert gcc_opp.opportunity_type == "research grant"
    assert gcc_opp.source_url == "https://globalchange.vt.edu/undergraduate/undergraduate-research-grants.html"
    assert "research" in gcc_opp.interests
    assert gcc_opp.contact_email == "stephmcbride@vt.edu"


def test_canonical_opportunity_validation(tmp_path: Path):
    """Loaded records must be instances of canonical Opportunity."""
    record = {
        "id": "test-opp-01",
        "title": "Undergraduate Research Assistant",
        "organization": "VT Computer Science",
        "opportunity_type": "research",
        "description": "AI systems research.",
        "source_url": "https://cs.vt.edu/research/01",
        "skills": ["Python", "PyTorch"],
        "interests": ["AI"],
        "eligibility": ["Undergraduate"],
        "majors": ["CS"],
        "class_years": ["Junior", "Senior"],
        "location": "Blacksburg, VA",
        "time_commitment": "10 hrs/week",
        "compensation": "$15/hr",
        "deadline": "2026-10-01",
        "apply_url": "https://cs.vt.edu/apply/01",
        "contact_name": "Dr. Smith",
        "contact_email": "smith@vt.edu",
    }
    file_path = tmp_path / "valid.json"
    file_path.write_text(json.dumps([record]), encoding="utf-8")

    result = load_and_validate_opportunities(file_path)
    assert len(result) == 1
    opp = result[0]
    assert isinstance(opp, Opportunity)
    assert opp.id == "test-opp-01"
    assert opp.skills == ["Python", "PyTorch"]
    assert opp.compensation == "$15/hr"


def test_malformed_record_fails_before_any_writes(tmp_path: Path):
    """A malformed record must raise SeedValidationError and prevent any writes."""
    records = [
        {
            "id": "valid-01",
            "title": "Valid Role",
            "organization": "VT",
            "opportunity_type": "research",
            "description": "A valid description.",
            "source_url": "https://vt.edu/valid",
        },
        {
            "id": "invalid-02",
            "title": "Invalid Role Without Required Source URL",
            "organization": "VT",
            "opportunity_type": "research",
            "description": "Missing source_url!",
            # missing source_url
        },
    ]
    file_path = tmp_path / "partially_invalid.json"
    file_path.write_text(json.dumps(records), encoding="utf-8")

    with patch("scripts.seed_opportunities.save_opportunities") as mock_save:
        with pytest.raises(SeedValidationError) as exc_info:
            seed_opportunities(file_path)

        # Must report which record failed
        assert "invalid-02" in str(exc_info.value)
        # Abort before writing any records
        mock_save.assert_not_called()


def test_empty_dataset_behavior(tmp_path: Path):
    """An empty array should be handled gracefully without error."""
    file_path = tmp_path / "empty.json"
    file_path.write_text("[]", encoding="utf-8")

    with patch("scripts.seed_opportunities.save_opportunities") as mock_save:
        result = seed_opportunities(file_path)
        assert result == []
        mock_save.assert_called_once_with([])


def test_save_opportunities_receives_complete_validated_collection(tmp_path: Path):
    """save_opportunities() is called with all validated Opportunity instances."""
    records = [
        {
            "id": f"opp-{i}",
            "title": f"Opportunity {i}",
            "organization": "VT Department",
            "opportunity_type": "internship",
            "description": f"Description {i}",
            "source_url": f"https://vt.edu/opp/{i}",
        }
        for i in range(3)
    ]
    file_path = tmp_path / "multiple.json"
    file_path.write_text(json.dumps(records), encoding="utf-8")

    with patch("scripts.seed_opportunities.save_opportunities") as mock_save:
        result = seed_opportunities(file_path)
        assert len(result) == 3
        mock_save.assert_called_once()
        saved_collection = mock_save.call_args[0][0]
        assert len(saved_collection) == 3
        assert [opp.id for opp in saved_collection] == ["opp-0", "opp-1", "opp-2"]
        assert all(isinstance(opp, Opportunity) for opp in saved_collection)


def test_nonexistent_file_raises_file_not_found(tmp_path: Path):
    """A missing file path must raise FileNotFoundError."""
    missing = tmp_path / "does_not_exist.json"
    with pytest.raises(FileNotFoundError):
        load_and_validate_opportunities(missing)


def test_invalid_json_syntax_raises_seed_validation_error(tmp_path: Path):
    """Corrupt JSON syntax must raise SeedValidationError."""
    corrupted = tmp_path / "corrupt.json"
    corrupted.write_text("{ not valid json", encoding="utf-8")
    with pytest.raises(SeedValidationError):
        load_and_validate_opportunities(corrupted)


def test_non_list_root_raises_seed_validation_error(tmp_path: Path):
    """A JSON object at top level instead of a list must raise SeedValidationError."""
    obj_file = tmp_path / "object.json"
    obj_file.write_text(json.dumps({"id": "opp-1"}), encoding="utf-8")
    with pytest.raises(SeedValidationError) as exc_info:
        load_and_validate_opportunities(obj_file)
    assert "Expected a top-level JSON array" in str(exc_info.value)

