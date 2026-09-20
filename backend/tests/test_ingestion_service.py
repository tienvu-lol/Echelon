"""Unit tests for the production opportunity ingestion service."""

from unittest.mock import MagicMock, patch

import pytest

from app.ingestion.base import BaseSourceAdapter
from app.models.opportunity import CareerTrackAffinity, Opportunity
from app.services.databricks_service import DatabricksServiceError
from app.services.ingestion_service import IngestionServiceError, run_ingestion_pipeline


class MockAdapter(BaseSourceAdapter):
    def __init__(self, opportunities: list[Opportunity]):
        self._opps = opportunities

    def fetch_opportunities(self):
        yield from self._opps


def _make_opp(
    id: str,
    title: str,
    org: str,
    apply_url: str = "https://example.com/apply",
    opp_type: str = "internship",
    career_tracks: list[CareerTrackAffinity] = None,
) -> Opportunity:
    return Opportunity(
        id=id,
        title=title,
        organization=org,
        opportunity_type=opp_type,
        description=f"{title} at {org}",
        source_url="https://example.com",
        apply_url=apply_url,
        active=True,
        career_tracks=career_tracks or [],
    )


class TestIngestionPipelineService:
    def test_run_ingestion_filters_and_persists(self):
        """Valid tech opportunities pass filters, receive classification, and persist to Databricks."""
        opp_valid_tech = _make_opp("tech-101", "Software Engineering Intern", "Acme Corp")
        opp_non_tech = _make_opp("mkt-202", "Marketing Intern", "Brand Corp")
        opp_low_quality = _make_opp("bad-303", "SE", "X")  # Too short title/org

        adapter = MockAdapter([opp_valid_tech, opp_non_tech, opp_low_quality])

        mock_tracks = [CareerTrackAffinity(track="software_engineering", weight=1.0)]

        with (
            patch(
                "app.services.gemini_service.classify_opportunity",
                return_value=mock_tracks,
            ) as mock_classify,
            patch(
                "app.services.databricks_service.save_opportunities"
            ) as mock_save,
        ):
            results = run_ingestion_pipeline(adapter=adapter, strict_tech_only=True)

        assert results["fetched"] == 3
        assert results["filtered"] == 1
        assert results["classified"] == 1
        assert results["persisted"] == 1

        mock_classify.assert_called_once()
        mock_save.assert_called_once()
        persisted_opps = mock_save.call_args[0][0]
        assert len(persisted_opps) == 1
        assert persisted_opps[0].id == "tech-101"
        assert persisted_opps[0].career_tracks == mock_tracks

    def test_rejects_dummy_simulation_records(self):
        """Simulation dummy records (e.g. id='1', '2', '3') must never be persisted."""
        dummy_1 = _make_opp("1", "Software Engineer", "Stripe")
        dummy_2 = _make_opp("2", "Marketing Intern", "Hubspot")
        dummy_3 = _make_opp("3", "Data Science Co-op", "Netflix")
        valid_opp = _make_opp("real-vt-42", "Robotics Research Assistant", "Virginia Tech")

        adapter = MockAdapter([dummy_1, dummy_2, dummy_3, valid_opp])

        with (
            patch("app.services.gemini_service.classify_opportunity", return_value=[]),
            patch("app.services.databricks_service.save_opportunities") as mock_save,
        ):
            results = run_ingestion_pipeline(adapter=adapter, strict_tech_only=False)

        assert results["fetched"] == 4
        assert results["persisted"] == 1
        saved_opps = mock_save.call_args[0][0]
        assert len(saved_opps) == 1
        assert saved_opps[0].id == "real-vt-42"

    def test_adapter_fetch_failure_raises(self):
        """If adapter fetch raises an unhandled error, IngestionServiceError is raised."""
        failing_adapter = MagicMock()
        failing_adapter.fetch_opportunities.side_effect = ConnectionError("Network down")

        with pytest.raises(IngestionServiceError) as excinfo:
            run_ingestion_pipeline(adapter=failing_adapter)
        assert "Adapter fetch failed" in str(excinfo.value)

    def test_databricks_persistence_failure_raises(self):
        """If Databricks persistence fails, IngestionServiceError is raised."""
        valid_opp = _make_opp("tech-555", "Cloud Systems Engineer", "TechCorp")
        adapter = MockAdapter([valid_opp])

        with (
            patch("app.services.gemini_service.classify_opportunity", return_value=[]),
            patch(
                "app.services.databricks_service.save_opportunities",
                side_effect=DatabricksServiceError("Warehouse unreachable"),
            ),
        ):
            with pytest.raises(IngestionServiceError) as excinfo:
                run_ingestion_pipeline(adapter=adapter, strict_tech_only=True)
            assert "Databricks persistence failed" in str(excinfo.value)

