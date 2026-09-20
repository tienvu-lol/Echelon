"""Virginia Tech public pages opportunity ingestion adapter."""

import hashlib
import logging
import re
from collections.abc import Iterator
from datetime import datetime, timezone

import httpx
from bs4 import BeautifulSoup

from app.ingestion.base import BaseSourceAdapter
from app.models.opportunity import Opportunity

logger = logging.getLogger(__name__)

class VirginiaTechAdapter(BaseSourceAdapter):
    """Adapter for scraping Virginia Tech experiential learning and research pages."""

    DEFAULT_URLS = [
        "https://globalchange.vt.edu/undergraduate/undergraduate-research-grants.html",
        "https://career.vt.edu/channels/campus-internexp/",
        "https://career.vt.edu/resources/ut-prosim-fund/",
        "https://career.vt.edu/channels/ceip/",
    ]
    GCC_GRANT_URL = DEFAULT_URLS[0]

    def __init__(self, urls: list[str] | None = None, client: httpx.Client | None = None):
        super().__init__()
        self.urls = urls or self.DEFAULT_URLS
        self.client = client

    def fetch_opportunities(self) -> Iterator[Opportunity]:
        """Fetch and yield standardized Opportunity objects from VT public pages."""
        own_client = False
        client = self.client
        if client is None:
            client = httpx.Client(timeout=15.0)
            own_client = True

        try:
            for url in self.urls:
                try:
                    logger.info(f"Fetching VT opportunities from {url}")
                    response = client.get(url)
                    response.raise_for_status()
                    opportunity = self._parse_page(url, response.text)
                    if opportunity is not None:
                        yield opportunity
                except Exception as e:
                    logger.warning(f"Failed to fetch or parse {url}: {e}")
        finally:
            if own_client and client:
                client.close()

    @staticmethod
    def _stable_id(url: str) -> str:
        digest = hashlib.sha256(url.encode("utf-8")).hexdigest()
        return f"vt_{digest}"

    @staticmethod
    def _parse_deadline(soup: BeautifulSoup) -> str | None:
        month_names = (
            "January|February|March|April|May|June|July|August|"
            "September|October|November|December"
        )
        pattern = re.compile(
            rf"\b({month_names})\s+(\d{{1,2}})(?:st|nd|rd|th)?,?\s+(\d{{4}})\b",
            re.IGNORECASE,
        )
        for element in soup.find_all(["p", "h2", "h3", "h4", "li"]):
            text = element.get_text(" ", strip=True)
            if "deadline" not in text.lower() and " due " not in f" {text.lower()} ":
                continue
            match = pattern.search(text)
            if match:
                parsed = datetime.strptime(
                    f"{match.group(1)} {match.group(2)} {match.group(3)}",
                    "%B %d %Y",
                )
                return parsed.date().isoformat()
        return None

    def _parse_page(self, url: str, html: str) -> Opportunity | None:
        """Parse only the currently actionable GCC grant page."""
        if url.rstrip("/") != self.GCC_GRANT_URL.rstrip("/"):
            return None

        soup = BeautifulSoup(html, "html.parser")

        title_tag = soup.find("h1")
        title = title_tag.get_text(" ", strip=True) if title_tag else ""
        if "undergraduate research grant" not in title.lower():
            return None

        content_div = soup.find("main") or soup.find("div", class_="content") or soup.body
        if not content_div:
            return None
        paragraphs = [
            paragraph.get_text(" ", strip=True)
            for paragraph in content_div.find_all("p")
            if paragraph.get_text(" ", strip=True)
        ]
        if not paragraphs:
            return None
        description = "\n\n".join(paragraphs)[:2000]
        deadline = self._parse_deadline(soup)
        if deadline is None:
            return None

        now = datetime.now(timezone.utc)

        return Opportunity(
            id=self._stable_id(url),
            title=title,
            organization="Virginia Tech Global Change Center",
            opportunity_type="grant",
            description=description,
            apply_url=url,
            source_url=url,
            source_name="Virginia Tech",
            active=True,
            first_seen_at=now,
            last_seen_at=now,
            deadline=deadline,
        )
