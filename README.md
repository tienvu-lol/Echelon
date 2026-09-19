# Echelon

> Campus Opportunity Navigator for Virginia Tech — VTHacks 2026

Echelon helps Virginia Tech students discover campus opportunities (internships, research, jobs, organizations, hackathons, scholarships, and more) through a Tinder-style swipe interface powered by AI.

## Architecture

```
iOS Native App → FastAPI Backend → Gemini API (AI)
                                 → Databricks (Data Platform)
```

- **Mobile**: Swift, SwiftUI, iOS 17+
- **Backend**: Python 3.12+ + FastAPI + Pydantic
- **AI**: Google Gemini API (resume parsing, embeddings, match explanations)
- **Data**: Databricks (Delta tables, Unity Catalog, AI Search)

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for full architecture details.

## Quick Start (Windows PowerShell)

### Prerequisites

- Python 3.12+ and [uv](https://docs.astral.sh/uv/)
- Node.js 18+ and npm
- Expo Go app on your phone (for mobile testing)

### 1. Clone and Configure

```powershell
git clone <your-repo-url>
cd Echelon

# Create environment file from template
Copy-Item .env.example .env

# Edit .env with your credentials
notepad .env
```

### 2. Backend Setup

```powershell
cd backend

# Install dependencies (creates .venv automatically)
uv sync

# Run the API server
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Verify: Open http://localhost:8000/health — should return `{"status": "ok"}`

### 3. Mobile Setup (Requires macOS)

Open `ios/Echelon/EchelonApp.swift` or the Xcode project (once generated) on a Mac:

1. Open Xcode on your Mac.
2. Create a new iOS App project (or open the generated one).
3. Add the `.swift` files from `ios/Echelon/` to the project.
4. Set `EXPO_PUBLIC_API_BASE_URL` logic via a build setting or hardcoded constant for now.
5. Hit `Cmd + R` to run in the iOS Simulator.

### 4. Test Backend Services

| Endpoint | What it tests | Requires |
|---|---|---|
| `GET /health` | Basic server health | Nothing |
| `GET /api/test/gemini` | Gemini API connectivity | `GEMINI_API_KEY` |
| `GET /api/test/databricks` | Databricks connectivity | Databricks config |

### 5. Run Tests

```powershell
cd backend
uv run pytest tests/ -v
```

## Environment Variables

| Variable | Description | Required For |
|---|---|---|
| `GEMINI_API_KEY` | Google Gemini API key | Gemini features |
| `GEMINI_GENERATIVE_MODEL` | Model for text generation (default: `gemini-3.8-flash`) | — |
| `GEMINI_EMBEDDING_MODEL` | Model for embeddings (default: `gemini-embedding-2`) | — |
| `GEMINI_EMBEDDING_DIMENSION` | Embedding vector size (default: `768`) | — |
| `DATABRICKS_HOST` | Databricks workspace URL | Databricks features |
| `DATABRICKS_CONFIG_PROFILE` | Profile name in `~/.databrickscfg` | Databricks auth |
| `DATABRICKS_WAREHOUSE_ID` | SQL Warehouse ID | SQL queries |
| `DATABRICKS_CATALOG` | Unity Catalog name | Data access |
| `DATABRICKS_SCHEMA` | Schema name | Data access |
| `DATABRICKS_AI_SEARCH_ENDPOINT` | AI Search endpoint name | Vector search |
| `DATABRICKS_AI_SEARCH_INDEX` | AI Search index name | Vector search |
| `EXPO_PUBLIC_API_BASE_URL` | Backend URL for mobile (default: `http://localhost:8000`) | Mobile |

## Project Structure

```
Echelon/
├── backend/           # Python FastAPI backend
│   ├── app/
│   │   ├── api/       # Route handlers
│   │   ├── models/    # Pydantic data models
│   │   ├── schemas/   # Request/response schemas
│   │   ├── services/  # Gemini + Databricks wrappers
│   │   ├── config.py  # Settings management
│   │   └── main.py    # FastAPI application
│   ├── tests/         # pytest test suite
│   └── pyproject.toml
├── ios/               # Swift / SwiftUI App
│   └── Echelon/
│       ├── Models/    # Swift Codable Structs
│       ├── Services/  # API Client
│       └── Views/     # SwiftUI Views
├── docs/              # Architecture documentation
├── ingestion/         # Data ingestion scripts (future)
├── tasks/             # Task tracking
├── .env.example       # Environment template
└── AGENTS.md          # AI agent instructions
```

## Hackathon Challenges

1. **Best Use of Gemini API** — Resume understanding, structured extraction, semantic embeddings, personalized explanations
2. **Deloitte / Databricks AI Challenge** — Delta tables, Unity Catalog, AI Search for semantic retrieval with precomputed Gemini embeddings

## License

VTHacks 2026 Hackathon Project
