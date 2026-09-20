"""Seed script: Bulk load opportunities into Databricks.

Reads verified opportunity records from backend/data/opportunities_seed.json,
validates every record against the canonical Opportunity domain model,
and calls save_opportunities() only if the entire dataset passes validation.

Run from inside backend/:
    uv run python scripts/seed_opportunities.py
"""

import json
import sys
from pathlib import Path

# Ensure backend root is on sys.path when run directly
backend_root = Path(__file__).resolve().parents[1]
if str(backend_root) not in sys.path:
    sys.path.insert(0, str(backend_root))

from app.models.opportunity import Opportunity
from app.services.databricks_service import save_opportunities

DEFAULT_SEED_FILE = backend_root / "data" / "opportunities_seed.json"


class SeedValidationError(Exception):
    """Raised when one or more opportunity records fail schema validation."""


def load_and_validate_opportunities(
    file_path: Path | str | None = None,
) -> list[Opportunity]:
    """Read and validate opportunity records from a JSON seed file.

    Args:
        file_path: Optional path to JSON file; defaults to
            backend/data/opportunities_seed.json.

    Returns:
        List of validated Opportunity instances.

    Raises:
        FileNotFoundError: If the seed file does not exist.
        SeedValidationError: If any record fails Pydantic validation or JSON structure is invalid.
    """
    path = Path(file_path) if file_path is not None else DEFAULT_SEED_FILE

    if not path.exists():
        raise FileNotFoundError(f"Seed file not found: {path}")

    with open(path, "r", encoding="utf-8") as f:
        try:
            data = json.load(f)
        except json.JSONDecodeError as exc:
            raise SeedValidationError(f"Invalid JSON syntax in {path}: {exc}") from exc

    if not isinstance(data, list):
        raise SeedValidationError(
            f"Expected a top-level JSON array of records, got {type(data).__name__}"
        )

    validated: list[Opportunity] = []
    for index, record in enumerate(data):
        if not isinstance(record, dict):
            raise SeedValidationError(
                f"Record at index {index} is not a valid JSON object: {record!r}"
            )

        identifier = record.get("id") or f"index {index}"
        try:
            opp = Opportunity(**record)
            validated.append(opp)
        except Exception as exc:
            raise SeedValidationError(
                f"Validation failed for record '{identifier}' at index {index}: {exc}"
            ) from exc

    return validated


def seed_opportunities(file_path: Path | str | None = None) -> list[Opportunity]:
    """Validate all opportunities in seed file, then persist to Databricks.

    Aborts immediately before writing any records if validation fails.

    Args:
        file_path: Optional path to JSON file.

    Returns:
        The list of saved Opportunity instances.
    """
    opportunities = load_and_validate_opportunities(file_path)

    if not opportunities:
        print("Seed dataset is empty. No opportunities to save.")
        save_opportunities([])
        return []

    print(f"Validated {len(opportunities)} opportunity record(s). Saving to Databricks...")
    save_opportunities(opportunities)

    print(f"Successfully saved {len(opportunities)} opportunity record(s):")
    for opp in opportunities:
        print(f"  - {opp.id}: {opp.title}")

    return opportunities


def main() -> None:
    try:
        seed_opportunities()
    except Exception as err:
        print(f"Error during opportunity seeding: {err}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()

