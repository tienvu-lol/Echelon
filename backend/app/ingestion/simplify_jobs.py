"""SimplifyJobs GitHub repository adapter.

Scrapes the Summer 2027 Internships README.md.
"""

import re
import urllib.request
from collections.abc import Iterator
from datetime import datetime

from app.ingestion.base import BaseSourceAdapter
from app.models.opportunity import Opportunity


class SimplifyJobsAdapter(BaseSourceAdapter):
    """Adapter for SimplifyJobs Summer2027-Internships."""

    URL = "https://raw.githubusercontent.com/SimplifyJobs/Summer2027-Internships/dev/README.md"

    def fetch_opportunities(self) -> Iterator[Opportunity]:
        try:
            req = urllib.request.Request(
                self.URL, headers={"User-Agent": "Mozilla/5.0"}
            )
            with urllib.request.urlopen(req) as response:
                content = response.read().decode("utf-8")
        except Exception as e:
            print(f"Failed to fetch {self.URL}: {e}")
            return

        # Markdown table parsing
        # Typical format:
        # | Company | Role | Location | Application/Link | Date Posted |
        # | --- | --- | --- | --- | --- |
        # | [Google](link) | Software Engineering Intern | Mountain View, CA | <a href="...">Apply</a> | Aug 15 |

        lines = content.split("\n")
        in_table = False

        for line in lines:
            line = line.strip()
            if not line.startswith("|"):
                in_table = False
                continue

            if "Company" in line and "Role" in line:
                in_table = True
                continue

            if in_table and "---" in line:
                continue

            if in_table:
                parts = [p.strip() for p in line.split("|")][1:-1]
                if len(parts) >= 4:
                    company_raw = parts[0]
                    role_raw = parts[1]
                    location_raw = parts[2]
                    apply_raw = parts[3]

                    # Clean markdown links
                    company_match = re.search(r"\[([^\]]+)\]", company_raw)
                    company = company_match.group(1) if company_match else company_raw

                    # Clean href
                    apply_match = re.search(r'href="([^"]+)"', apply_raw)
                    if apply_match:
                        apply_url = apply_match.group(1)
                    else:
                        link_match = re.search(r"\[([^\]]+)\]\(([^\)]+)\)", apply_raw)
                        apply_url = link_match.group(2) if link_match else None

                    # Ignore locked ones usually containing 🔒
                    if "🔒" in apply_raw or "🔒" in role_raw:
                        continue

                    if not apply_url:
                        continue

                    # create ID deterministically based on URL and role to avoid duplicates
                    # or just use uuid since we'll upsert by URL ideally, but schema has ID as primary key.
                    # Actually, our schema has id as primary key. Let's make deterministic ID
                    import hashlib

                    hash_str = f"{company}{role_raw}{apply_url}".encode()
                    opp_id = hashlib.md5(hash_str).hexdigest()

                    yield Opportunity(
                        id=opp_id,
                        title=role_raw,
                        organization=company,
                        opportunity_type="internship",
                        description=f"{role_raw} at {company} in {location_raw}",
                        source_url=self.URL,
                        source_name="SimplifyJobs Summer2027",
                        location=location_raw,
                        apply_url=apply_url,
                        active=True,
                        first_seen_at=datetime.utcnow(),
                        last_seen_at=datetime.utcnow(),
                    )


if __name__ == "__main__":
    adapter = SimplifyJobsAdapter()
    for opp in adapter.fetch_opportunities():
        print(opp.title, opp.organization)
        break
