"""Local Pipeline Simulation.

Runs the generic web scraper, applies filters, and simulates the recommendation 
engine offline without touching Databricks.
"""

import sys
import os
import json
import asyncio
from pathlib import Path

# Add backend directory to sys.path so we can import app modules
backend_dir = Path(__file__).resolve().parents[1]
sys.path.append(str(backend_dir))

from dotenv import load_dotenv
load_dotenv(backend_dir.parent / ".env")

from app.ingestion.web_scraper import WebScraperAdapter
from app.ingestion.filters import IngestionPipeline
from app.models.student import StudentProfile
from app.models.recommendation import CareerPreferences, CareerTrackAffinity
from app.services import candidate_retrieval, gemini_service
import logging

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)

def run_simulation():
    print("="*60)
    print("ECHELON PIPELINE SIMULATION (OFFLINE)")
    print("="*60)
    
    # 1. Scrape Generic Site
    target = "https://careers.google.com/jobs/results/?q=intern"
    print(f"\n[1] Starting Web Scraper for: {target}")
    scraper = WebScraperAdapter(target_url=target, source_name="Google Careers", organization="Google")
    
    raw_opps = list(scraper.fetch_opportunities())
    print(f"    -> Scraped {len(raw_opps)} raw opportunities.")
    
    if not raw_opps:
        print("    -> (Target is likely JS-rendered. Falling back to Y Combinator jobs...)")
        scraper = WebScraperAdapter(target_url="https://www.ycombinator.com/jobs/role/software-engineer", source_name="YC", organization="Various")
        raw_opps = list(scraper.fetch_opportunities())
        print(f"    -> Scraped {len(raw_opps)} raw opportunities from fallback.")
        
    from app.models.opportunity import Opportunity
    from datetime import datetime, timezone
    import hashlib
    
    dummy_opps = [
        Opportunity(id="1", title="Software Engineering Intern", organization="Stripe", source_url="http://stripe.com/jobs", apply_url="http://stripe.com/jobs", opportunity_type="internship", description="Build APIs.", active=True, first_seen_at=datetime.now(timezone.utc), last_seen_at=datetime.now(timezone.utc)),
        Opportunity(id="2", title="Marketing Intern", organization="Hubspot", source_url="http://hubspot.com/jobs", apply_url="http://hubspot.com/jobs", opportunity_type="internship", description="SEO and marketing.", active=True, first_seen_at=datetime.now(timezone.utc), last_seen_at=datetime.now(timezone.utc)),
        Opportunity(id="3", title="Data Science Co-op", organization="Netflix", source_url="http://netflix.com/jobs", apply_url="http://netflix.com/jobs", opportunity_type="internship", description="Analyze viewing data using Python.", active=True, first_seen_at=datetime.now(timezone.utc), last_seen_at=datetime.now(timezone.utc)),
    ]
    raw_opps.extend(dummy_opps)

    # 2. Filtering
    print("\n[2] Passing through Ingestion Filters & Tests...")
    pipeline = IngestionPipeline(strict_tech_only=True)
    filtered_opps = pipeline.process_batch(raw_opps)
    
    for opp in filtered_opps:
        print(f"    PASS: {opp.title} @ {opp.organization}")

    # 3. Gemini Enrichment
    print("\n[3] AI Enrichment: Classifying Career Tracks...")
    for opp in filtered_opps:
        if opp.id in ["1", "3"]:
            tracks = gemini_service.classify_opportunity(opp)
            opp.career_tracks = tracks
            print(f"    Classified [{opp.organization}] {opp.title} -> {[t.track for t in tracks]}")

    # 4. Mocking a User Profile
    print("\n[4] Parsing Fake User Data (Simulating iOS Onboarding)...")
    student = StudentProfile(
        id="sim-123",
        major="Computer Science",
        class_year="Junior",
        skills=["Python", "SQL", "Pandas"],
        interests=["Machine Learning", "Data Infrastructure"],
        experience=["Built a recommendation engine for a hackathon."]
    )
    prefs = CareerPreferences(
        career_tracks=[
            CareerTrackAffinity(track="data_science", weight=0.8),
            CareerTrackAffinity(track="backend_platform", weight=0.6)
        ]
    )
    print(f"    Student: Junior in {student.major}. Loves {', '.join(student.interests)}")

    # 5. Running the Recommendation Engine
    print("\n[5] Executing Recommendation Algorithm (Heuristic + LLM Reranking)...")
    
    candidates = candidate_retrieval.get_top_candidates(student, prefs, all_opportunities=filtered_opps, limit=10)
    print(f"    Heuristics retrieved {len(candidates)} candidates.")
    
    if candidates:
        recommendations = gemini_service.rerank_opportunities(student, prefs, candidates)
        print("\nFINAL RECOMMENDATIONS:")
        for idx, rec in enumerate(recommendations, 1):
            print(f"\n  {idx}. {rec.opportunity.title} @ {rec.opportunity.organization}")
            print(f"     Match Score: {rec.score}/100")
            print(f"     Why: {rec.match_reason}")
    else:
        print("    No candidates passed heuristics.")

    print("\n" + "="*60)
    print("SIMULATION COMPLETE. (No Databricks connection was made)")
    print("="*60)

if __name__ == "__main__":
    run_simulation()
