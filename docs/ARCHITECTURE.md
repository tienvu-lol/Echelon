# Architecture — Echelon

## System Overview

Echelon is a three-tier application: mobile client, API backend, and two external AI/data services.

```
┌─────────────┐     HTTP/JSON     ┌──────────────┐     SDK      ┌──────────────┐
│  iOS App    │ ──────────────── │   FastAPI    │ ──────────── │  Gemini API  │
│  (SwiftUI)  │                  │  (Backend)   │              │  (Google)    │
└─────────────┘                  │              │     SDK      ┌──────────────┐
                                 │              │ ──────────── │  Databricks  │
                                 └──────────────┘              │  (Data)      │
                                                               └──────────────┘
```

## Gemini Responsibilities

| Capability | API Used | Model |
|---|---|---|
| Resume/document understanding | `generate_content` with PDF | `gemini-3.8-flash` |
| Structured profile extraction | `generate_content` with JSON schema | `gemini-3.8-flash` |
| Opportunity normalization | `generate_content` with JSON schema | `gemini-3.8-flash` |
| Semantic embeddings | `embed_content` | `gemini-embedding-2` (768d) |
| Match explanations | `generate_content` | `gemini-3.8-flash` |

All Gemini calls are in `backend/app/services/gemini.py`.

## Databricks Responsibilities

| Capability | Service Used |
|---|---|
| Store opportunity data | Delta tables in Unity Catalog |
| Store student profiles | Delta tables in Unity Catalog |
| Store swipe history | Delta tables in Unity Catalog |
| Store precomputed embeddings | ARRAY<FLOAT> column in Delta |
| Semantic retrieval | AI Search (Delta Sync Index) |
| Metadata filtering | AI Search filters |

All Databricks calls are in `backend/app/services/databricks.py`.

## Recommendation Pipeline

```
1. Student uploads resume via iOS App
2. iOS App sends PDF + metadata to FastAPI
3. FastAPI sends document to Gemini
4. Gemini returns structured StudentProfile (JSON schema)
5. FastAPI validates with Pydantic
6. FastAPI persists profile to Databricks
7. FastAPI builds profile_text from structured fields
8. FastAPI generates 768d embedding via Gemini (gemini-embedding-2)
9. Opportunities are pre-embedded with the SAME model and dimension
10. FastAPI queries Databricks AI Search with student embedding
11. AI Search applies metadata filters (class year, major, deadline, type)
12. FastAPI receives candidate set
13. FastAPI sends finalists to Gemini for personalized explanations
14. FastAPI returns opportunity cards to iOS App
15. Every swipe is recorded in Databricks
```

## Embedding Strategy

- **Model**: `gemini-embedding-2`
- **Dimension**: 768
- **Storage**: `ARRAY<FLOAT>` column in Databricks Delta table
- **Index**: Databricks AI Search Delta Sync Index with self-managed (precomputed) embeddings
- **Critical rule**: Both student profiles and opportunities MUST be embedded with the same model and same dimensionality for cosine similarity to be meaningful.

## API Routes

| Method | Path | Purpose |
|---|---|---|
| GET | `/health` | Health check |
| POST | `/api/profile/parse` | Parse resume → structured profile |
| POST | `/api/profile` | Create profile from structured data |
| GET | `/api/opportunities/recommendations` | Get personalized recommendations |
| POST | `/api/swipes` | Record a swipe |
| GET | `/api/saved` | Get saved opportunities |
| POST | `/api/saved/{opportunity_id}` | Save an opportunity |

## Security Boundaries

- Mobile app has NO access to Gemini API keys or Databricks credentials
- All AI and data operations are server-side only
- CORS is configured on the backend (permissive during development)
- No authentication system in the MVP (added post-hackathon)
