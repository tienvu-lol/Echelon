# Echelon Backend Handoff & Implementation To-Do List

> **Target Audience:** Backend Engineers & AI Subagents / Coding Agents  
> **Status:** High Priority  
> **Scope:** FastAPI Service, Databricks Delta Lakehouse, Gemini Reranker / Agent, Rate Limiting, Swipes & Application Tracking

---

## Executive Summary & iOS Frontend Context

The iOS frontend (`ios/EchelonTestRun`) has completed the entire Discover batching architecture, swipe interactions, matches tracking, profile settings, and AI Opportunity Advisor integration. The iOS client is completely compiling with zero errors.

To achieve production readiness and complete end-to-end integration, the backend requires completion of **6 core modules**. Each module is specified below with exact API contracts, Databricks Lakehouse table DDLs, authentication requirements, and test suites.

---

## 1. Discover Feed Rate Limiting & 7-Card Batching Engine

### Context
* **Frontend Requirement:** The Discover page serves opportunities in strict batches of **exactly 7**.
* **Rate Limit Rule:** A student can manually refresh opportunities a maximum of **3 times within any rolling 1-hour window**.
* The **initial load** of 7 cards does **NOT** count towards the 3 refreshes.
* The backend is the single source of truth for rate limiting.

### API Contract: `GET /api/opportunities/recommendations`
* **Query Parameters:**
  * `limit` (integer, default `7`, max `50`)
  * `is_refresh` (boolean, optional, default `false`)
* **Headers:** `Authorization: Bearer <Firebase ID Token>`

#### Response Payload (`200 OK`)
```json
{
  "student_id": "firebase_uid_123",
  "opportunities": [
    {
      "opportunity": {
        "id": "opp-001",
        "title": "Systems Software Intern",
        "organization": "Virginia Tech CS Department",
        "opportunity_type": "internship",
        "description": "Work on distributed systems and cloud infrastructure.",
        "skills": ["Python", "Linux", "C++"],
        "location": "Blacksburg, VA",
        "paid": true,
        "deadline": "2027-03-01",
        "apply_url": "https://cs.vt.edu/apply/001"
      },
      "score": 94,
      "match_reason": "Matches your Systems coursework and Linux proficiency.",
      "matched_traits": ["skills", "career_tracks"],
      "gaps": [],
      "career_track_fit": ["software_engineering"]
    }
  ],
  "can_refresh": true,
  "refreshes_remaining": 2,
  "next_refresh_available_at": "2026-09-20T03:45:00Z"
}
```

#### Rate Limit Exceeded Response (`429 Too Many Requests`)
```json
{
  "error": "rate_limit_exceeded",
  "message": "Maximum of 3 refreshes per hour reached. Please try again later.",
  "refreshes_remaining": 0,
  "next_refresh_available_at": "2026-09-20T03:45:00Z"
}
```

### Tasks for Backend Agent
1. **Create Refresh Tracking Table in Databricks:**
   ```sql
   CREATE TABLE IF NOT EXISTS workspace.default.user_refresh_events (
       id STRING,
       student_id STRING,
       refreshed_at TIMESTAMP
   ) USING DELTA;
   ```
2. **Implement Rolling 1-Hour Window Check:**
   * Query `user_refresh_events` where `student_id = :uid` and `refreshed_at > current_timestamp() - INTERVAL 1 HOUR`.
   * If `count >= 3` and `is_refresh == true`, raise `HTTPException(status_code=429)`.
   * Return `next_refresh_available_at` calculated from the timestamp of the oldest event in the active window + 1 hour.
3. **Exclude Swiped & Applied IDs:**
   * Query `workspace.default.swipes` and `workspace.default.applications` for the user.
   * Filter candidates: `WHERE id NOT IN (SELECT opportunity_id FROM swipes WHERE student_id = :uid)`.

---

## 2. Swipe Persistence & Dynamic Affinity Updates (`/api/swipes`)

### Context
* Route file `backend/app/api/swipes.py` exists but is currently **unregistered** in `backend/app/main.py` and has stubbed persistence (`# TODO: Persist to Databricks`).

### API Contract: `POST /api/swipes`
* **Headers:** `Authorization: Bearer <Firebase ID Token>`
* **Request Body:**
```json
{
  "opportunity_id": "opp-001",
  "direction": "right" // enum: "left" (pass) | "right" (match)
}
```
* **Response Body (`200 OK` / `201 Created`):**
```json
{
  "id": "swipe-uuid-456",
  "student_id": "firebase_uid_123",
  "opportunity_id": "opp-001",
  "direction": "right",
  "created_at": "2026-09-20T03:00:00Z"
}
```

### Tasks for Backend Agent
1. **Register Swipes Router:**
   In `backend/app/main.py`:
   ```python
   from app.api import swipes
   app.include_router(swipes.router)
   ```
2. **Create Databricks Swipes Table:**
   ```sql
   CREATE TABLE IF NOT EXISTS workspace.default.swipes (
       id STRING,
       student_id STRING,
       opportunity_id STRING,
       direction STRING,
       created_at TIMESTAMP
   ) USING DELTA;
   ```
3. **Inject Auth & Persist Record:**
   * Add `current_user: dict = Depends(get_current_user)` to `create_swipe` in `swipes.py`.
   * Use `uid = current_user["uid"]`, do not trust body `student_id`.
   * Execute insert/append record via `databricks_service.py`.
4. **Dynamic Career Preference Feedback Loop:**
   * When `direction == "right"`, retrieve opportunity career tracks and skills.
   * Increment corresponding track weights in `workspace.default.career_preferences`.

---

## 3. Application Workflow Tracking (`/api/opportunities/{id}/apply`)

### Context
* In Echelon, **Matching is NOT Applying**.
  * A right-swipe matches an opportunity (storing it in Matches -> Not Applied).
  * Clicking "Apply" opens the link and transitions it to Applied.
* The frontend records applications via `POST /api/opportunities/{id}/apply`.

### API Contract: `POST /api/opportunities/{opportunity_id}/apply`
* **Headers:** `Authorization: Bearer <Firebase ID Token>`
* **Response Body (`200 OK`):**
```json
{
  "status": "success",
  "application_id": "app-uuid-789",
  "opportunity_id": "opp-001",
  "student_id": "firebase_uid_123",
  "applied_at": "2026-09-20T03:00:00Z"
}
```

### Tasks for Backend Agent
1. **Create Applications Table:**
   ```sql
   CREATE TABLE IF NOT EXISTS workspace.default.applications (
       id STRING,
       student_id STRING,
       opportunity_id STRING,
       status STRING,
       applied_at TIMESTAMP
   ) USING DELTA;
   ```
2. **Implement Endpoint in `backend/app/api/opportunities.py`:**
   * Route: `@router.post("/opportunities/{opportunity_id}/apply")`
   * Secure with `Depends(get_current_user)`.
   * Insert record into `workspace.default.applications`.

---

## 4. Multimodal Resume Ingestion & Profile Parsing (`/api/profile/parse`)

### Context
* Endpoint `POST /api/profile/parse` exists in `backend/app/api/profile.py`.
* Uses Gemini 3.8 Flash to extract structured JSON from raw PDF bytes.

### API Contract: `POST /api/profile/parse`
* **Headers:** `Authorization: Bearer <Firebase ID Token>`
* **Content-Type:** `multipart/form-data`
* **Form Field:** `resume` (PDF file binary)

#### Return Payload (`StudentProfile`):
```json
{
  "major": "Computer Science",
  "class_year": "Junior",
  "graduation_year": 2027,
  "skills": ["Python", "Swift", "C++", "PyTorch"],
  "interests": ["Machine Learning", "Autonomous Systems"],
  "coursework": ["Data Structures", "Algorithms", "Operating Systems"],
  "experience": ["Autonomy Software Intern @ YC Startup"],
  "bio": "Passionate about systems engineering and applied ML."
}
```

### Tasks for Backend Agent
1. **Verify Gemini Multimodal Parsing:**
   * Ensure `parse_resume` handles multi-page PDFs up to 10MB cleanly.
   * Ensure both `class_year` and `graduation_year` are populated.
2. **Persist to Databricks:**
   * Verify `save_student_profile(uid, parsed_profile)` updates `workspace.default.student_profiles`.

---

## 5. Conversational Agent & RAG Context (`/api/agent/chat`)

### Context
* `backend/app/api/agent.py` exposes `POST /api/agent/chat`.
* The frontend Opportunity Detail view provides an integrated AI chat where users can ask specific questions about the opportunity (e.g. "Why am I a good match?", "What interview questions should I expect?").

### Enhancing `AgentChatRequest`
```python
class AgentChatRequest(BaseModel):
    message: str
    opportunity_id: str | None = None
    opportunity_title: str | None = None
    organization: str | None = None
```

### Tasks for Backend Agent
1. **Inject Opportunity Context into Agent System Prompt:**
   * If `opportunity_id` is passed, retrieve the full `Opportunity` record from Databricks.
   * Ground Gemini with real qualifications, tech stack, and deadlines.
   * Strictly prevent hallucination of contact info or requirements.

---

## 6. Lakehouse Schema Migration Verification

### Tasks for Backend Agent
Execute and verify the schema migration script:
```bash
uv run python backend/scripts/migrate_databricks_schema.py
```
Ensure all tables exist in `workspace.default`:
1. `student_profiles`
2. `opportunities`
3. `career_preferences`
4. `swipes`
5. `applications`
6. `user_refresh_events`

---

## Verification & Testing Commands

Run the full backend test suite to verify all integrations:
```bash
# 1. Run unit and pipeline tests
uv run pytest backend/tests/test_opportunities.py
uv run pytest backend/tests/test_recommendation_pipeline.py
uv run pytest backend/tests/test_ingestion_service.py

# 2. Start local server
uv run uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

---
*Created by Echelon iOS Team for seamless backend agent handoff.*
