"""Ingestion Filtering and Testing Pipeline.

Applies strict data quality and domain relevance filters to scraped opportunities
before they are allowed to be passed to the Gemini recommendation engine or
saved to the database.
"""

import logging
import re

from app.models.opportunity import Opportunity

logger = logging.getLogger(__name__)


class IngestionPipeline:
    """Filters and sanitizes raw scraped opportunities."""

    def __init__(self, strict_tech_only: bool = True):
        self.strict_tech_only = strict_tech_only

        # Keywords that indicate a role is relevant to Echelon (Tech/CS)
        self.tech_keywords = {
            "software",
            "developer",
            "engineer",
            "data",
            "ai",
            "machine learning",
            "cyber",
            "security",
            "systems",
            "cloud",
            "frontend",
            "backend",
            "fullstack",
            "full-stack",
            "product",
            "qa",
            "quant",
        }

        # Keywords that explicitly disqualify a role (e.g. non-tech internships)
        self.banned_keywords = {
            "marketing",
            "sales",
            "hr",
            "human resources",
            "legal",
            "accounting",
            "finance (non-quant)",
            "business development",
        }

    def _has_valid_links(self, opp: Opportunity) -> bool:
        if not opp.apply_url:
            return False
        # Very basic URL regex check
        return bool(re.match(r"^https?://", opp.apply_url))

    def _is_tech_role(self, opp: Opportunity) -> bool:
        title = opp.title.lower()
        desc = opp.description.lower() if opp.description else ""

        if opp.source_name == "Virginia Tech":
            return self._is_campus_relevant(title, desc)

        # Immediate rejection if banned keyword in title
        if any(banned in title for banned in self.banned_keywords):
            return False

        if not self.strict_tech_only:
            return True

        # Must contain at least one tech keyword in title or heavily in description
        if any(tech in title for tech in self.tech_keywords):
            return True

        # If title is vague, check if description has strong tech indicators
        tech_hits = sum(1 for tech in self.tech_keywords if tech in desc)
        if tech_hits >= 2:
            return True

        return False

    def _is_campus_relevant(self, title: str, desc: str) -> bool:
        """Campus specific relevance heuristic. More lenient but rejects explicit non-tech."""
        if any(banned in title for banned in self.banned_keywords):
            return False

        campus_tech_keywords = self.tech_keywords.union({
            "computational", "web", "database", "analytics", "it support", "programming", "scripting"
        })

        if any(tech in title for tech in campus_tech_keywords):
            return True

        tech_hits = sum(1 for tech in campus_tech_keywords if tech in desc)
        if tech_hits >= 1:
            return True

        return False

    def _is_high_quality(self, opp: Opportunity) -> bool:
        """Tests if the parsing successfully captured necessary metadata."""
        if not opp.title or len(opp.title) < 4:
            return False
        if not opp.organization or len(opp.organization) < 2:
            return False
        return True

    def process_batch(self, raw_opportunities: list[Opportunity]) -> list[Opportunity]:
        """Runs the test and filter suite over a batch of opportunities."""
        filtered = []
        rejected_counts = {"invalid_link": 0, "not_tech": 0, "low_quality": 0}

        # 1. Deduplication (URL or ID based)
        seen_urls = set()
        deduped = []
        for opp in raw_opportunities:
            if opp.apply_url in seen_urls:
                continue
            seen_urls.add(opp.apply_url)
            deduped.append(opp)

        # 2. Quality and Domain Filtering
        for opp in deduped:
            if not self._has_valid_links(opp):
                rejected_counts["invalid_link"] += 1
                continue

            if not self._is_high_quality(opp):
                rejected_counts["low_quality"] += 1
                continue

            if not self._is_tech_role(opp):
                rejected_counts["not_tech"] += 1
                continue

            filtered.append(opp)

        logger.info(
            f"Ingestion Pipeline Results: Passed {len(filtered)} | "
            f"Rejected: {rejected_counts}"
        )
        return filtered
