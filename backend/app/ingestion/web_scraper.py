"""Generic Web Scraper for CS Internships.

Uses httpx and BeautifulSoup to heuristically scrape generic job boards or
university sites for internship opportunities.
"""

import hashlib
import logging
from collections.abc import Iterator
from datetime import datetime
from datetime import datetime, timezone
from urllib.parse import urljoin

import httpx
from bs4 import BeautifulSoup

from app.ingestion.base import BaseSourceAdapter
from app.models.opportunity import Opportunity

logger = logging.getLogger(__name__)


class WebScraperAdapter(BaseSourceAdapter):
    """Generic web scraper for expanding beyond structured GitHub repositories.

    Uses heuristic parsing to find job links. Looks for <a> tags containing
    keywords like 'intern', 'software', 'developer'.
    """

    def __init__(
        self, target_url: str, source_name: str, organization: str = "Unknown"
    ):
        super().__init__()
        self.target_url = target_url
        self.source_name = source_name
        self.organization = organization
        self.client = httpx.Client(
            headers={
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) EchelonBot/1.0"
            },
            follow_redirects=True,
            timeout=10.0,
        )

    def fetch_opportunities(self) -> Iterator[Opportunity]:
        logger.info(f"Initiating generic web scrape for {self.target_url}")
        logger.info("Initiating generic web scrape for %s", self.target_url)

        try:
            response = self.client.get(self.target_url)
            response.raise_for_status()
        except Exception as e:
            logger.error(f"Failed to fetch {self.target_url}: {e}")
            logger.error("Failed to fetch %s: %s", self.target_url, e)
            return

        soup = BeautifulSoup(response.text, "html.parser")

        # Heuristics: find links that might be internships
        keywords = [
            "intern",
            "software",
            "developer",
            "engineer",
            "data",
            "analyst",
            "co-op",
        ]

        # To avoid yielding the same link twice
        seen_urls = set()

        for a_tag in soup.find_all("a", href=True):
            text = a_tag.get_text(separator=" ", strip=True)
            href = a_tag["href"]

            # Normalize href to absolute URL if necessary
            if href.startswith("/"):
                from urllib.parse import urljoin

                href = urljoin(self.target_url, href)

            if not href.startswith("http"):
                continue

            if href in seen_urls:
                continue

            text_lower = text.lower()
            href_lower = href.lower()

            # If the link text or URL strongly implies it's a tech internship role
            if any(k in text_lower for k in keywords) and (
                "intern" in text_lower or "intern" in href_lower
            ):
                # Context extraction: Try to find surrounding paragraph for a description
                parent = a_tag.find_parent(["div", "li", "td"])
                description = (
                    parent.get_text(separator=" ", strip=True) if parent else text
                )

                # Clean up description length
                if len(description) > 500:
                    description = description[:497] + "..."

                seen_urls.add(href)

                opp_id = hashlib.md5(
                    f"{self.organization}{text}{href}".encode()
                ).hexdigest()

                yield Opportunity(
                    id=opp_id,
                    title=text if len(text) > 3 else "Internship Opportunity",
                    organization=self.organization,
                    opportunity_type="internship",
                    description=description,
                    source_url=self.target_url,
                    source_name=self.source_name,
                    apply_url=href,
                    active=True,
                    first_seen_at=datetime.now(timezone.utc),
                    last_seen_at=datetime.now(timezone.utc),
                )
