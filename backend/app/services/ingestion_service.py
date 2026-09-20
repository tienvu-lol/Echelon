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
from app.models.opportunity import Opportunity
from app.services import databricks_service, gemini_service

logger = logging.getLogger(__name__)

# Known dummy/simulation IDs and placeholders that must never be written to Databricks
_DISALLOWED_DUMMY_IDS = {"1", "2", "3", "dummy", "test-dummy", "mock-opp"}
_DISALLOWED_DUMMY_ORGS = {"mockorg", "dummycorp", "testorganization"}


class IngestionServiceError(Exception):
    """Raised when ingestion pipeline execution fails."""


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
    adapter: Optional[BaseSourceAdapter] = None,
    strict_tech_only: bool = True,
    max_items: Optional[int] = None,
) -> dict[str, Any]:
    """Execute the full ingestion pipeline from source adapter to Databricks lakehouse.

    Workflow:
    1. Fetch opportunities from source adapter (defaults to SimplifyJobsAdapter).
    2. Filter out simulation/dummy records.
    3. Apply quality and tech domain relevance filters via IngestionPipeline.
    4. Enrich passed opportunities with Gemini career track classification.
    5. Persist/upsert validated opportunities into Databricks.

    Args:
        adapter: Source adapter instance (e.g. SimplifyJobsAdapter).
        strict_tech_only: Whether to filter out non-tech opportunities.
        max_items: Optional limit on the number of items to enrich and persist.

    Returns:
        Summary dict containing counts of fetched, filtered, classified, and persisted opportunities.
    """
    if adapter is None:
        adapter = SimplifyJobsAdapter()

    logger.info("Starting ingestion with adapter %s...", adapter.__class__.__name__)

    try:
        raw_items = list(adapter.fetch_opportunities())
    except Exception as exc:
        logger.error("Failed to fetch opportunities from adapter: %s", exc)
        raise IngestionServiceError(f"Adapter fetch failed: {exc}") from exc

    logger.info("Fetched %d raw opportunities from source.", len(raw_items))

    # Reject any dummy/mock records
    legit_items = [opp for opp in raw_items if _is_real_opportunity(opp)]
    if len(legit_items) < len(raw_items):
        logger.info(
            "Rejected %d simulation/dummy records.", len(raw_items) - len(legit_items)
        )

    # 2. Filter via IngestionPipeline
    pipeline = IngestionPipeline(strict_tech_only=strict_tech_only)
    passed_items = pipeline.process_batch(legit_items)
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
        "fetched": len(raw_items),
        "filtered": len(passed_items),
        "classified": classified_count,
        "persisted": persisted_count,
    }

