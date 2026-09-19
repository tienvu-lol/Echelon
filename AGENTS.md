# Project Instructions

## Product

We are building a Virginia Tech campus opportunity navigator.

Students upload a resume and enter interests.
The backend parses their profile using Gemini.
Opportunities are stored and retrieved through Databricks.
The iOS frontend is written separately in SwiftUI.

## Backend stack

- Python
- FastAPI
- Pydantic
- Gemini API
- Databricks
- uv for dependency management

## Architecture

SwiftUI frontend -> FastAPI backend -> Gemini + Databricks

The frontend must never access Gemini or Databricks directly.

## Rules

- All secrets come from environment variables.
- Never commit `.env`.
- Never fabricate opportunity data, application links, recruiter names, or contact information.
- API responses must use Pydantic models.
- External provider logic belongs in `/services`.
- Route files should remain thin.
- Business logic should not live directly inside route handlers.
- Write tests for non-trivial logic.
- Do not edit unrelated files.
- Read docs/API_CONTRACTS.md before changing response formats.

## Commands

Install:
`uv sync`

Run:
`uv run uvicorn app.main:app --reload`

Tests:
`uv run pytest`