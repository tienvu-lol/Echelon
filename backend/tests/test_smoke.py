"""Full-breadth and full-depth smoke tests for the Echelon backend.

Verifies:
1. OpenAPI specification generation, schema integrity, and Swagger/ReDoc endpoints.
2. Complete route map and authentication contract integrity across all endpoints.
3. CLI script execution, argument parsing, and import integrity.
"""

import json
from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


class TestOpenAPISchemaAndDocs:
    """Verifies that the entire FastAPI app builds valid OpenAPI documentation."""

    def test_openapi_json_is_valid(self):
        response = client.get("/openapi.json")
        assert response.status_code == 200
        schema = response.json()

        assert schema.get("openapi", "").startswith("3.")
        assert schema.get("info", {}).get("title") == "Echelon Backend"

        paths = schema.get("paths", {})
        expected_endpoints = [
            "/health",
            "/test/gemini",
            "/test/databricks",
            "/api/auth/me",
            "/api/profile/me",
            "/api/profile",
            "/api/profile/parse",
            "/api/opportunities/recommendations",
            "/api/agent/chat",
        ]
        for endpoint in expected_endpoints:
            assert endpoint in paths, f"Missing registered endpoint: {endpoint}"

    def test_docs_and_redoc_endpoints(self):
        docs_resp = client.get("/docs")
        assert docs_resp.status_code == 200

        redoc_resp = client.get("/redoc")
        assert redoc_resp.status_code == 200

    def test_pydantic_schemas_registered(self):
        response = client.get("/openapi.json")
        components = response.json().get("components", {}).get("schemas", {})

        expected_schemas = [
            "Opportunity",
            "StudentProfile",
            "RecommendationsResponse",
            "RecommendationResponseItem",
            "CareerTrackAffinity",
            "AgentChatRequest",
            "AgentChatResponse",
            "ProfileCreateRequest",
        ]
        for s in expected_schemas:
            assert s in components, f"Missing component schema: {s}"


class TestAuthProtectionSmoke:
    """Smoke test ensuring every private endpoint enforces authentication."""

    @pytest.mark.parametrize(
        "method,endpoint,kwargs",
        [
            ("GET", "/api/auth/me", {}),
            ("GET", "/api/profile/me", {}),
            ("POST", "/api/profile", {"json": {"major": "CS"}}),
            (
                "POST",
                "/api/profile/parse",
                {"files": {"resume": ("resume.pdf", b"%PDF-dummy", "application/pdf")}},
            ),
            ("GET", "/api/opportunities/recommendations", {}),
            ("POST", "/api/agent/chat", {"json": {"message": "Hello"}}),
        ],
    )
    def test_protected_routes_reject_unauthenticated_requests(
        self, method: str, endpoint: str, kwargs: dict
    ):
        req_fn = getattr(client, method.lower())
        response = req_fn(endpoint, **kwargs)
        # HTTPBearer raises 401 Unauthorized or 403 Forbidden
        assert response.status_code in (401, 403), f"Endpoint {endpoint} allowed unauthenticated access!"


class TestCLIScriptsSmoke:
    """Smoke tests for backend CLI scripts ensuring imports and execution paths function."""

    def test_migrate_databricks_schema_script(self):
        from scripts.migrate_databricks_schema import main as migrate_main

        with patch("scripts.migrate_databricks_schema.migrate_schema") as mock_mig:
            mock_mig.return_value = {
                "tables_checked": ["student_profiles", "opportunities", "career_preferences"],
                "columns_added": [],
                "rows_updated": 0,
            }
            migrate_main()
            mock_mig.assert_called_once()

    def test_run_ingestion_script(self):
        import sys
        from scripts.run_ingestion import main as ingestion_main

        test_args = ["run_ingestion.py", "--max-items", "5", "--allow-non-tech"]
        with (
            patch.object(sys, "argv", test_args),
            patch("scripts.run_ingestion.run_ingestion_pipeline") as mock_pipe,
        ):
            mock_pipe.return_value = {
                "fetched": 5,
                "filtered": 5,
                "classified": 5,
                "persisted": 5,
            }
            ingestion_main()
            mock_pipe.assert_called_once_with(strict_tech_only=False, max_items=5)

    def test_seed_opportunities_script(self):
        from scripts import seed_opportunities as seed_mod

        with patch("scripts.seed_opportunities.save_opportunities") as mock_save:
            saved = seed_mod.seed_opportunities()
            mock_save.assert_called_once()
            assert isinstance(saved, list)
            assert len(saved) >= 1

            # Test main() CLI wrapper
            seed_mod.main()
            assert mock_save.call_count == 2

    def test_simulate_pipeline_script(self):
        from scripts.simulate_pipeline import run_simulation

        mock_tracks = [MagicMock(track="software_engineering", weight=1.0)]
        mock_gemini_recs = [
            MagicMock(
                opportunity=MagicMock(title="Mock Title", organization="Mock Org"),
                score=90,
                match_reason="Great fit",
                eligibility_status="ELIGIBLE",
            )
        ]

        with (
            patch("app.ingestion.web_scraper.WebScraperAdapter.fetch_opportunities", return_value=[]),
            patch("app.services.gemini_service.classify_opportunity", return_value=mock_tracks),
            patch("app.services.gemini_service.rerank_opportunities", return_value=mock_gemini_recs),
        ):
            run_simulation()

