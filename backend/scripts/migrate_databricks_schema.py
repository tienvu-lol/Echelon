"""Safe idempotent Databricks schema migration script.

Ensures student_profiles, opportunities, and career_preferences tables
exist in workspace.default with live-compatible Delta DDL.
Adds any missing Phase 2 columns to the opportunities table via ALTER TABLE,
and sets active = true for existing rows where active is NULL.

Usage:
    uv run python backend/scripts/migrate_databricks_schema.py
"""

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

from app.services.databricks_service import DatabricksServiceError, migrate_schema

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("migrate_databricks_schema")


def main() -> None:
    logger.info("Starting safe Databricks schema migration...")
    try:
        summary = migrate_schema()
        logger.info("Databricks schema migration completed successfully!")
        logger.info("Summary of operations:")
        logger.info("  Tables verified: %s", ", ".join(summary.get("tables_checked", [])))
        cols_added = summary.get("columns_added", [])
        if cols_added:
            logger.info("  Columns added to opportunities: %s", ", ".join(cols_added))
        else:
            logger.info("  Columns added to opportunities: (none, schema was up-to-date)")
        logger.info("  Rows checked/updated: %s", summary.get("rows_updated", 0))
    except DatabricksServiceError as err:
        logger.error("Databricks schema migration failed: %s", err)
        sys.exit(1)
    except Exception as exc:
        logger.exception("Unexpected failure during schema migration: %s", exc)
        sys.exit(1)


if __name__ == "__main__":
    main()

