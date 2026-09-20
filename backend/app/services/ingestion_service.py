"""Ingestion service for pulling opportunities, filtering, enriching, and persisting to Databricks.

This module provides the production ingestion pipeline separate from user-facing
recommendation workflows. It does NOT run automatically on user requests or UI refreshes.
"""

import logging
from collections.abc import Sequence
from typing import Any, Optional

from app.ingestion.base import BaseSourceAdapter
from app.ingestion.filters import IngestionPipeline
from app.ingestion.simplify_jobs import SimplifyJobsAdapter
from app.ingestion.virginia_tech import VirginiaTechAdapter
from app.models.opportunity import Opportunity
from app.services import databricks_service, gemini_service

logger = logging.getLogger(__name__)

# Known dummy/simulation IDs and placeholders that must never be written to Databricks
_DISALLOWED_DUMMY_IDS = {"1", "2", "3", "dummy", "test-dummy", "mock-opp"}
_DISALLOWED_DUMMY_ORGS = {"mockorg", "dummycorp", "testorganization"}


class IngestionServiceError(Exception):
    """Raised when ingestion pipeline execution fails."""


def get_adapters_for_source(source: str) -> list[tuple[str, BaseSourceAdapter]]:
    """Return the configured adapters for a source selector."""
    adapters = {
        "simplify": SimplifyJobsAdapter,
        "vt": VirginiaTechAdapter,
    }
    if source == "all":
        return [(name, adapter()) for name, adapter in adapters.items()]
    if source not in adapters:
        raise ValueError(f"Unknown source: {source}")
    return [(source, adapters[source]())]


def _is_real_opportunity(opp: Opportunity) -> bool:
    """Safeguard: verify an opportunity is not a known test/simulation dummy."""
    if opp.id.lower() in _DISALLOWED_DUMMY_IDS:
        return False
    if opp.organization.lower() in _DISALLOWED_DUMMY_ORGS:
        return False
    # Title must be reasonable length
    if not opp.title or len(opp.title.strip()) < 3:
        return False
    # Must have a valid apply URL or source URL
    url = opp.apply_url or opp.source_url
    if not url or not url.startswith(("http://", "https://")):
        return False
    return True


def run_ingestion_pipeline(
    source: str = "all",
    strict_tech_only: bool = True,
    max_items: Optional[int] = None,
) -> dict[str, Any]:
    """Execute the full ingestion pipeline from source adapters to Databricks lakehouse."""
    adapters_to_run = get_adapters_for_source(source)

    logger.info("Starting ingestion with sources %s...", source)

    raw_items = []
    processed_sources = 0
    failed_sources = []
    for source_name, adapter in adapters_to_run:
        logger.info("Running adapter: %s", adapter.__class__.__name__)
        try:
            items = list(adapter.fetch_opportunities())
            logger.info("Adapter %s returned %d items", adapter.__class__.__name__, len(items))
            raw_items.extend(items)
            processed_sources += 1
        except Exception as e:
            logger.error("Adapter %s failed: %s", adapter.__class__.__name__, e)
            failed_sources.append(source_name)

    logger.info("Fetched %d total raw opportunities.", len(raw_items))

    # Reject any dummy/mock records
    legit_items = [opp for opp in raw_items if _is_real_opportunity(opp)]
    if len(legit_items) < len(raw_items):
        logger.info(
            "Rejected %d simulation/dummy records.", len(raw_items) - len(legit_items)
        )

    # 2. Filter via IngestionPipeline
    pipeline = IngestionPipeline(strict_tech_only=strict_tech_only)
    passed_items = pipeline.process_batch(legit_items)
    filtered_count = len(raw_items) - len(passed_items)
    logger.info("Passed ingestion filters: %d opportunities.", len(passed_items))

    if max_items is not None and max_items > 0:
        passed_items = passed_items[:max_items]
        logger.info("Truncated to max_items=%d for processing.", max_items)

    # 3. Enrich with Gemini classification if career tracks are missing
    classified_count = 0
    for opp in passed_items:
        if not opp.career_tracks:
            try:
                tracks = gemini_service.classify_opportunity(opp)
                if tracks:
                    opp.career_tracks = tracks
                    classified_count += 1
            except Exception as exc:
                logger.warning(
                    "Gemini classification skipped for %s (%s): %s",
                    opp.id,
                    opp.title,
                    exc,
                )

    # 4. Upsert into Databricks
    persisted_count = 0
    if passed_items:
        try:
            databricks_service.save_opportunities(passed_items)
            persisted_count = len(passed_items)
            logger.info("Successfully persisted %d opportunities into Databricks.", persisted_count)
        except Exception as exc:
            logger.error("Failed to persist opportunities into Databricks: %s", exc)
            raise IngestionServiceError(f"Databricks persistence failed: {exc}") from exc

    return {
        "processed_sources": processed_sources,
        "failed_sources": failed_sources,
        "total_fetched": len(raw_items),
        "total_filtered": filtered_count,
        "total_classified": classified_count,
        "total_persisted": persisted_count,
        "fetched": len(raw_items),
        "filtered": len(passed_items),
        "classified": classified_count,
        "persisted": persisted_count,
    }

