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

## Backend Architecture

Backend integrations must remain isolated behind service modules.

External providers:
- Gemini / Google Agent Platform -> Gemini service
- Databricks -> Databricks service
- Firebase -> authentication service/dependency

API routes must not contain provider-specific business logic.

Do not directly couple provider services to each other.
For example:
- GeminiService must not instantiate DatabricksService.
- DatabricksService must not instantiate GeminiService.
- Firebase authentication must not contain recommendation logic.

Cross-service orchestration belongs in a dedicated application/service layer.

Before modifying shared configuration, API contracts, dependencies,
models, or app initialization, inspect existing implementations and
avoid breaking other integrations.

Never rename or change an existing environment variable without
coordinating the change.

Never modify another integration's service files unless the current
task explicitly requires it.