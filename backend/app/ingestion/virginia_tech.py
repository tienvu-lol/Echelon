"""Virginia Tech public pages opportunity ingestion adapter."""

import logging
from collections.abc import Iterator
from datetime import datetime, timezone
import httpx
from bs4 import BeautifulSoup

from app.ingestion.base import BaseSourceAdapter
from app.models.opportunity import Opportunity, CareerTrackAffinity

logger = logging.getLogger(__name__)

class VirginiaTechAdapter(BaseSourceAdapter):
    """Adapter for scraping Virginia Tech experiential learning and research pages."""

    DEFAULT_URLS = [
        "https://globalchange.vt.edu/undergraduate/undergraduate-research-grants.html",
        "https://career.vt.edu/channels/campus-internexp/",
        "https://career.vt.edu/resources/ut-prosim-fund/",
        "https://career.vt.edu/channels/ceip/",
    ]

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
                    yield self._parse_page(url, response.text)
                except Exception as e:
                    logger.warning(f"Failed to fetch or parse {url}: {e}")
        finally:
            if own_client and client:
                client.close()

    def _parse_page(self, url: str, html: str) -> Opportunity:
        """Parse a VT page into a single Opportunity representing the program."""
        soup = BeautifulSoup(html, "html.parser")
        
        # Basic extraction (can be refined based on actual HTML structure)
        title_tag = soup.find("h1")
        title = title_tag.get_text(strip=True) if title_tag else "Virginia Tech Opportunity"
        
        # Extract main content
        content_div = soup.find("main") or soup.find("div", class_="content") or soup.body
        description = "No description available."
        if content_div:
            paragraphs = content_div.find_all("p")
            if paragraphs:
                description = "\n\n".join(p.get_text(strip=True) for p in paragraphs if p.get_text(strip=True))[:2000]

        now = datetime.now(timezone.utc)
        
        return Opportunity(
            id=f"vt_{hash(url)}",
            title=title,
            organization="Virginia Tech",
            opportunity_type="program",
            description=description,
            apply_url=url,
            source_url=url,
            source_name="Virginia Tech",
            active=True,
            first_seen_at=now,
            last_seen_at=now,
            # Provide sensible defaults for a university program
            remote_status="on_site",
            location="Blacksburg, VA",
            degree_levels=["bachelors"],
            work_authorization_requirements=[],
            career_tracks=[CareerTrackAffinity(track="research", weight=1.0), CareerTrackAffinity(track="campus", weight=1.0)],
        )
