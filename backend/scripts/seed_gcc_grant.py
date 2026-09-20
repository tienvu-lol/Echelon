"""Seed script: Global Change Center Undergraduate Research Grant 2026-27.

One-off development seed script for Databricks opportunities table.
Run from inside backend/:
    uv run python scripts/seed_gcc_grant.py
"""

import sys
from pathlib import Path

# Ensure backend root is in sys.path when run directly
backend_root = Path(__file__).resolve().parents[1]
if str(backend_root) not in sys.path:
    sys.path.insert(0, str(backend_root))

from app.models.opportunity import Opportunity
from app.services.databricks_service import save_opportunity

OPPORTUNITY_RECORD = Opportunity(
    id="vt-gcc-undergrad-research-grant-2026-27",
    title="Global Change Center Undergraduate Research Grant 2026-27",
    organization="Global Change Center at Virginia Tech",
    opportunity_type="research grant",
    description=(
        "Virginia Tech's Global Change Center offers undergraduate research grants "
        "supporting projects related to global change science, engineering, "
        "social science, and the humanities."
    ),
    source_url="https://globalchange.vt.edu/undergraduate/undergraduate-research-grants.html",
    skills=[],
    interests=["research", "global change", "environment", "society"],
    eligibility=[
        "Current Virginia Tech undergraduate student",
        "Must be mentored and endorsed by an active GCC faculty member",
    ],
    majors=[],
    class_years=[],
    location=None,
    time_commitment=None,
    compensation="$250-$1,000 research grant",
    deadline="2026-09-25",
    apply_url=None,
    contact_name="Steph McBride",
    contact_email="stephmcbride@vt.edu",
)


def seed() -> None:
    print(f"Seeding opportunity: {OPPORTUNITY_RECORD.id}...")
    save_opportunity(OPPORTUNITY_RECORD)
    print(f"Successfully saved opportunity: {OPPORTUNITY_RECORD.id}")


if __name__ == "__main__":
    seed()

