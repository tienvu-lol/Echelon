"""SimplifyJobs Summer 2027 structured listing adapter."""

import hashlib
import json
import logging
import urllib.request
from collections.abc import Iterator
from datetime import datetime, timezone
from typing import Any
from urllib.parse import urlparse

from app.ingestion.base import BaseSourceAdapter
from app.models.opportunity import Opportunity

logger = logging.getLogger(__name__)


class SimplifyJobsAdapter(BaseSourceAdapter):
    """Adapter for SimplifyJobs Summer2027-Internships."""

    URL = (
        "https://raw.githubusercontent.com/SimplifyJobs/Summer2027-Internships/"
        "dev/.github/scripts/listings.json"
    )
    SOURCE_URL = (
        "https://github.com/SimplifyJobs/Summer2027-Internships/"
        "blob/dev/.github/scripts/listings.json"
    )

    @staticmethod
    def _stable_id(url: str) -> str:
        return f"simplify_{hashlib.sha256(url.encode('utf-8')).hexdigest()}"

    @staticmethod
    def _string_list(value: Any) -> list[str]:
        if not isinstance(value, list):
            return []
        return [item.strip() for item in value if isinstance(item, str) and item.strip()]

    @staticmethod
    def _posted_date(value: Any) -> str | None:
        if isinstance(value, bool) or not isinstance(value, (int, float)):
            return None
        try:
            return datetime.fromtimestamp(value, tz=timezone.utc).date().isoformat()
        except (OverflowError, OSError, ValueError):
            return None

    def _parse_listing(self, listing: Any) -> Opportunity | None:
        if not isinstance(listing, dict) or listing.get("active") is not True:
            return None
        if "is_visible" in listing and listing["is_visible"] is not True:
            return None

        company = listing.get("company_name")
        title = listing.get("title")
        apply_url = listing.get("url")
        if not all(
            isinstance(value, str) and value.strip()
            for value in (company, title, apply_url)
        ):
            return None
        if urlparse(apply_url).scheme not in {"http", "https"}:
            return None

        listing_id = listing.get("id")
        opportunity_id = (
            listing_id.strip()
            if isinstance(listing_id, str) and listing_id.strip()
            else self._stable_id(apply_url)
        )
        locations = self._string_list(listing.get("locations"))
        degrees = self._string_list(listing.get("degrees"))
        category = listing.get("category")
        sponsorship = listing.get("sponsorship")
        now = datetime.now(timezone.utc)

        return Opportunity(
            id=opportunity_id,
            title=title.strip(),
            organization=company.strip(),
            opportunity_type="internship",
            description=title.strip(),
            source_url=self.SOURCE_URL,
            source_name="SimplifyJobs Summer2027",
            source_age=self._posted_date(listing.get("date_posted")),
            active=True,
            first_seen_at=now,
            last_seen_at=now,
            interests=[category.strip()]
            if isinstance(category, str) and category.strip()
            else [],
            degree_levels=degrees,
            work_authorization_requirements=[sponsorship.strip()]
            if isinstance(sponsorship, str) and sponsorship.strip()
            else [],
            location=" | ".join(locations) if locations else None,
            apply_url=apply_url.strip(),
        )

    def fetch_opportunities(self) -> Iterator[Opportunity]:
        """Fetch active, visible opportunities from the canonical JSON store."""
        try:
            request = urllib.request.Request(
                self.URL, headers={"User-Agent": "Mozilla/5.0"}
            )
            with urllib.request.urlopen(request) as response:
                listings = json.loads(response.read().decode("utf-8"))
        except Exception as exc:
            logger.error("Failed to fetch %s: %s", self.URL, exc)
            return

        if not isinstance(listings, list):
            logger.error("SimplifyJobs listing store did not contain a JSON array")
            return

        for listing in listings:
            opportunity = self._parse_listing(listing)
            if opportunity is not None:
                yield opportunity


if __name__ == "__main__":
    adapter = SimplifyJobsAdapter()
    for opp in adapter.fetch_opportunities():
        print(opp.title, opp.organization)
        break
