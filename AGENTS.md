# AGENTS.md — Echelon

## Project

Echelon is a mobile-first campus opportunity navigator for Virginia Tech, built for VTHacks 2026.

## Architecture

### Runtime Flow

```
Expo Mobile App
  → FastAPI Backend
      → Gemini API (AI processing)
      → Databricks (Data platform)
```

FastAPI is the sole orchestration layer. The mobile app never contacts Gemini or Databricks directly.

### Technology Stack

| Layer | Technology |
|---|---|
| Mobile | Swift, SwiftUI, iOS 17+ |
| Backend | Python 3.12+, FastAPI, Pydantic, uv |
| AI | Google Gemini API via `google-genai` SDK |
| Data | Databricks (Delta, Unity Catalog, AI Search) via `databricks-sdk` |
| Embeddings | `gemini-embedding-2` at 768 dimensions |

## Non-Negotiable Rules

1. **Gemini and Databricks are NOT directly coupled.** FastAPI coordinates both.
2. **No secrets in Git.** All credentials in `.env` (gitignored). Only `.env.example` is committed.
3. **Only the backend calls Gemini and Databricks.** The mobile app communicates only with FastAPI.
4. **Gemini calls go through `backend/app/services/gemini.py`.** No Gemini imports elsewhere.
5. **Databricks calls go through `backend/app/services/databricks.py`.** No Databricks imports elsewhere.
6. **No hallucinated data.** If a field (email, URL, deadline, etc.) is not in the source, return null.
7. **No arbitrary match percentages.** Recommendations are based on embedding similarity via AI Search.
8. **No paid cloud resources without explicit approval.**
9. **Validate Gemini responses with Pydantic.** Use structured output schemas, not free-form JSON parsing.
10. **Graceful degradation.** Missing credentials or service outages must produce clear error messages, never crashes.

## Key Files

| File | Purpose |
|---|---|
| `backend/app/services/gemini.py` | All Gemini API interactions |
| `backend/app/services/databricks.py` | All Databricks interactions |
| `backend/app/services/recommendations.py` | Recommendation pipeline (future) |
| `backend/app/config.py` | Settings from environment variables |
| `backend/app/models/` | Pydantic data models |
| `ios/Echelon/Services/APIService.swift` | iOS → Backend API client |

## Data Models

- `StudentProfile` — Student resume/profile data
- `Opportunity` — Campus opportunity with embedding
- `Swipe` — Left/right swipe record
- `SavedOpportunity` — Explicitly saved opportunity

See `docs/DATA_MODEL.md` for full field specifications.

## Development Priorities

- Simplicity over abstraction
- Working vertical slices over completeness
- Readable code over clever code
- Clear interfaces over flexible ones
- Reliability over performance
