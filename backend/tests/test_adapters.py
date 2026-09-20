"""Unit tests for ingestion source adapters (SimplifyJobsAdapter and WebScraperAdapter).

All HTTP requests and network calls are mocked.
"""

from io import BytesIO
from unittest.mock import MagicMock, patch

import pytest

from app.ingestion.simplify_jobs import SimplifyJobsAdapter
from app.ingestion.web_scraper import WebScraperAdapter


class TestSimplifyJobsAdapter:
    SAMPLE_MARKDOWN = """
## Summer 2027 Internships

| Company | Role | Location | Application/Link | Date Posted |
| --- | --- | --- | --- | --- |
| [Google](https://google.com) | Software Engineering Intern | Mountain View, CA | <a href="https://google.com/apply">Apply</a> | Aug 15 |
| Microsoft | Data Science Intern | Redmond, WA | [Apply](https://careers.microsoft.com/apply) | Aug 16 |
| LockedCorp | Secret Intern | Hidden | 🔒 Locked | Aug 17 |
| BrokenCorp | Missing Apply Link | Nowhere | Not a link | Aug 18 |
"""

    def test_parses_markdown_table_successfully(self):
        adapter = SimplifyJobsAdapter()

        mock_response = MagicMock()
        mock_response.read.return_value = self.SAMPLE_MARKDOWN.encode("utf-8")
        mock_response.__enter__.return_value = mock_response

        with patch("urllib.request.urlopen", return_value=mock_response):
            opps = list(adapter.fetch_opportunities())

        assert len(opps) == 2

        google_opp = opps[0]
        assert google_opp.organization == "Google"
        assert google_opp.title == "Software Engineering Intern"
        assert google_opp.location == "Mountain View, CA"
        assert google_opp.apply_url == "https://google.com/apply"
        assert google_opp.active is True
        assert google_opp.opportunity_type == "internship"

        msft_opp = opps[1]
        assert msft_opp.organization == "Microsoft"
        assert msft_opp.title == "Data Science Intern"
        assert msft_opp.location == "Redmond, WA"
        assert msft_opp.apply_url == "https://careers.microsoft.com/apply"

    def test_fetch_error_handled_gracefully(self):
        adapter = SimplifyJobsAdapter()

        with patch("urllib.request.urlopen", side_effect=Exception("Network error")):
            opps = list(adapter.fetch_opportunities())

        assert opps == []


class TestWebScraperAdapter:
    SAMPLE_HTML = """
    <html>
        <body>
            <div>
                <a href="/jobs/swe-intern">Software Engineering Intern</a>
                <p>Join our team for the summer to build distributed backend systems.</p>
            </div>
            <div>
                <a href="https://careers.example.com/data-analyst-intern">Data Analyst Intern</a>
            </div>
            <div>
                <a href="/about-us">About Us</a>
            </div>
            <div>
                <!-- Duplicate link -->
                <a href="/jobs/swe-intern">Software Engineering Intern (Duplicate)</a>
            </div>
        </body>
    </html>
    """

    def test_scrapes_internship_links_with_heuristics(self):
        adapter = WebScraperAdapter(
            target_url="https://careers.example.com",
            source_name="ExampleCareers",
            organization="ExampleCorp",
        )

        mock_response = MagicMock()
        mock_response.text = self.SAMPLE_HTML
        mock_response.raise_for_status = MagicMock()

        with patch.object(adapter.client, "get", return_value=mock_response):
            opps = list(adapter.fetch_opportunities())

        assert len(opps) == 2
        swe_opp = next(o for o in opps if "Software Engineering" in o.title)
        assert swe_opp.organization == "ExampleCorp"
        assert swe_opp.apply_url == "https://careers.example.com/jobs/swe-intern"
        assert swe_opp.source_name == "ExampleCareers"
        assert "distributed backend systems" in swe_opp.description

        data_opp = next(o for o in opps if "Data Analyst" in o.title)
        assert data_opp.apply_url == "https://careers.example.com/data-analyst-intern"

    def test_http_error_handled_gracefully(self):
        adapter = WebScraperAdapter(
            target_url="https://careers.example.com",
            source_name="ExampleCareers",
        )

        with patch.object(adapter.client, "get", side_effect=Exception("HTTP 500")):
            opps = list(adapter.fetch_opportunities())

        assert opps == []

