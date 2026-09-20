"""Manual CLI runner for the opportunity ingestion pipeline.

Pulls live opportunities from the configured source adapter, filters them for quality
and tech domain relevance, enriches them with Gemini career track classification,
and upserts them into Databricks.

Usage:
    uv run python backend/scripts/run_ingestion.py [--max-items 25] [--allow-non-tech]
"""

import argparse
import logging
import sys
from pathlib import Path

# Add backend directory to sys.path so app modules import cleanly
_BACKEND_DIR = Path(__file__).resolve().parents[1]
if str(_BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(_BACKEND_DIR))

# Ensure root .env is loaded
_REPO_ROOT = _BACKEND_DIR.parent
from dotenv import load_dotenv

load_dotenv(_REPO_ROOT / ".env")

from app.services.ingestion_service import IngestionServiceError, run_ingestion_pipeline

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("run_ingestion")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Run opportunity ingestion from source to Databricks."
    )
    parser.add_argument(
        "--max-items",
        type=int,
        default=None,
        help="Maximum number of passed opportunities to classify and persist.",
    )
    parser.add_argument(
        "--allow-non-tech",
        action="store_true",
        help="Disable strict tech-only filtering.",
    )

    args = parser.parse_args()

    logger.info("Initializing opportunity ingestion run...")
    try:
        results = run_ingestion_pipeline(
            strict_tech_only=not args.allow_non_tech,
            max_items=args.max_items,
        )
        logger.info("Ingestion completed successfully!")
        logger.info("  Fetched:     %d", results["fetched"])
        logger.info("  Passed:      %d", results["filtered"])
        logger.info("  Classified:  %d", results["classified"])
        logger.info("  Persisted:   %d", results["persisted"])
    except IngestionServiceError as err:
        logger.error("Ingestion pipeline failed: %s", err)
        sys.exit(1)
    except Exception as exc:
        logger.exception("Unexpected error during ingestion: %s", exc)
        sys.exit(1)


if __name__ == "__main__":
    main()

