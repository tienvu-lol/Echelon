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


from app.ingestion.virginia_tech import VirginiaTechAdapter
import httpx

class TestVirginiaTechAdapter:
    GCC_URL = VirginiaTechAdapter.DEFAULT_URLS[0]
    UT_PROSIM_URL = VirginiaTechAdapter.DEFAULT_URLS[2]
    CEIP_URL = VirginiaTechAdapter.DEFAULT_URLS[3]
    INTERNEXP_URL = VirginiaTechAdapter.DEFAULT_URLS[1]

    SAMPLE_GCC_HTML = """
    <html>
        <body>
            <main>
                <h1>UNDERGRADUATE RESEARCH GRANTS</h1>
                <p>The Global Change Center at Virginia Tech sponsors undergraduate research projects.</p>
                <p>Submissions for Undergraduate Research Grants for 2026-2027 are due September 25, 2026.</p>
            </main>
        </body>
    </html>
    """

    def test_emits_active_gcc_grant_without_fabricated_fields(self):
        mock_response = MagicMock()
        mock_response.text = self.SAMPLE_GCC_HTML
        mock_response.raise_for_status = MagicMock()
        mock_client = MagicMock(spec=httpx.Client)
        mock_client.get.return_value = mock_response
        adapter = VirginiaTechAdapter(urls=[self.GCC_URL], client=mock_client)

        opps = list(adapter.fetch_opportunities())

        assert len(opps) == 1
        opp = opps[0]
        assert opp.organization == "Virginia Tech Global Change Center"
        assert opp.title == "UNDERGRADUATE RESEARCH GRANTS"
        assert opp.opportunity_type == "grant"
        assert opp.source_name == "Virginia Tech"
        assert opp.source_url == self.GCC_URL
        assert opp.apply_url == self.GCC_URL
        assert opp.deadline == "2026-09-25"
        assert opp.active is True
        assert "Global Change Center" in opp.description
        assert opp.career_tracks == []
        assert opp.contact_name is None
        assert opp.contact_email is None
        assert opp.compensation is None
        assert opp.eligibility == []
        assert opp.location is None

    def test_id_is_stable_and_deterministic(self):
        first = VirginiaTechAdapter._stable_id(self.GCC_URL)
        second = VirginiaTechAdapter._stable_id(self.GCC_URL)

        assert first == second
        assert first == (
            "vt_"
            "4100f8e3724523fc92ac5cb56a6e13164e8cb92611b4b449066001450ad2f507"
        )

    @pytest.mark.parametrize("url", [UT_PROSIM_URL, CEIP_URL, INTERNEXP_URL])
    def test_rejects_non_actionable_landing_pages(self, url):
        mock_response = MagicMock()
        mock_response.text = """
        <html><body><main>
            <h1>Virginia Tech Program</h1>
            <p>General information about this program and prior participants.</p>
        </main></body></html>
        """
        mock_response.raise_for_status = MagicMock()
        mock_client = MagicMock(spec=httpx.Client)
        mock_client.get.return_value = mock_response

        assert list(VirginiaTechAdapter(urls=[url], client=mock_client).fetch_opportunities()) == []

    def test_handles_fetch_error(self):
        adapter = VirginiaTechAdapter(urls=[self.GCC_URL])
        mock_client = MagicMock(spec=httpx.Client)
        mock_client.get.side_effect = httpx.RequestError("Network error")
        adapter.client = mock_client

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

