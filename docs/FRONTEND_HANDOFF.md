# Echelon: Frontend & Backend Integration Status

This document outlines the current state of the Echelon FastAPI backend, detailing what is fully implemented and ready for frontend integration, versus what is still pending or required from the frontend team.

---

## 1. Authentication Flow (Crucial for Frontend)

The backend uses **Firebase Authentication** as the absolute source of truth for identity.

**Frontend Responsibilities:**
1. The iOS app handles user login/signup using the Firebase Client SDK.
2. The app retrieves the user's **Firebase ID Token**.
3. **Every authenticated API request** must include this token in the HTTP header:
   ```http
   Authorization: Bearer <FIREBASE_ID_TOKEN>
   ```

*Note: The backend does not require passing `uid` in query parameters or request bodies. The backend automatically extracts and verifies the `uid` securely from the Bearer token via `get_current_user`.*

---

## 2. What the Backend Currently Offers (Ready to Use)

The core recommendation logic, LLM sandboxing, resume parsing, and database engines are fully implemented. The following endpoints are live:

### A. Echelon Agent Chat
*   **Endpoint:** `POST /api/agent/chat`
*   **Headers:** `Authorization: Bearer <Firebase ID Token>`
*   **Request Body:**
    ```json
    { "message": "I'm looking for a data science internship in New York." }
    ```
*   **Response:**
    ```json
    {
      "reply": "I'd love to help! I've updated your career preferences to focus on Data Science roles in New York.",
      "preferences_updated": true
    }
    ```
*   **Backend Details:** Wrapped in a strict safety harness restricting conversation to career topics. It reads the student's Databricks profile and current preferences, processes the conversation using Gemini, and automatically updates their Databricks `CareerPreferences` in the background when new preferences are learned.

### B. Opportunity Recommendations
*   **Endpoint:** `GET /api/opportunities/recommendations?limit=10`
*   **Headers:** `Authorization: Bearer <Firebase ID Token>`
*   **Query Parameters:** `limit` (optional integer, default: `10`, min: `1`, max: `50`)
*   **Response Structure (`RecommendationsResponse`):**
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
            "source_url": "https://cs.vt.edu/opp/001",
            "source_name": "VT CS",
            "active": true,
            "skills": ["Python", "Linux"],
            "interests": ["Software Systems"],
            "career_tracks": [{"track": "software_engineering", "weight": 1.0}],
            "location": "Blacksburg, VA",
            "apply_url": "https://cs.vt.edu/apply/001"
          },
          "score": 95,
          "match_reason": "Matches your CS major, Linux skills, and systems interest.",
          "matched_traits": ["skills", "career_tracks"],
          "gaps": [],
          "career_track_fit": ["software_engineering"],
          "eligibility_status": "ELIGIBLE",
          "eligibility_notes": ["Student meets all known eligibility criteria."]
        }
      ]
    }
    ```
*   **iOS Contract Note:** Swift `APIService.swift` must decode the nested `RecommendationsResponse` schema where opportunity attributes are nested under `.opportunity` and the personalized rationale is in `.match_reason`.
*   **Backend Pipeline:**
    1. Reads the authenticated student's profile and career preferences from Databricks.
    2. Retrieves active candidates from Databricks lakehouse.
    3. Evaluates strict eligibility constraints (class year, major, school restrictions).
    4. Deterministic heuristic ranking (track overlap, skill overlap, interest overlap).
    5. Gemini LLM reranking and personalized match reason generation.

### C. Resume Upload & Profile Parsing
*   **Endpoint:** `POST /api/profile/parse`
*   **Headers:** `Authorization: Bearer <Firebase ID Token>`
*   **Content-Type:** `multipart/form-data`
*   **Form Fields:**
    - `resume`: PDF file (required, binary)
    - `bio`: optional free-text bio string
    - `interests`: optional comma-separated or text interests string
*   **Response:** `StudentProfile`
    ```json
    {
      "major": "Computer Science",
      "class_year": "Junior",
      "bio": "Passionate about distributed systems.",
      "skills": ["Python", "C++", "Docker"],
      "interests": ["Cloud Computing", "AI"],
      "coursework": ["Operating Systems", "Data Structures"],
      "experience": ["Undergraduate Teaching Assistant"]
    }
    ```
*   **Backend Details:** Parses PDF resume bytes using Gemini structured output and automatically persists the extracted profile into Databricks (`workspace.default.student_profiles`) keyed by the user's Firebase UID.

### D. Student Profile Management
*   **`GET /api/profile/me`:** Returns the authenticated user's `StudentProfile` from Databricks (returns 404 if not yet created).
*   **`POST /api/profile`:** Manually creates or updates a profile without a resume via `ProfileCreateRequest` (`major`, `graduation_year`, `skills`, `interests`, `coursework`, `experience`, `bio`).

### E. Ingestion Ecosystem (Offline / Background)
*   **Script:** `uv run python backend/scripts/run_ingestion.py [--max-items 25] [--allow-non-tech]`
*   Scrapes verified listings via source adapters (e.g., `SimplifyJobsAdapter`, `WebScraperAdapter`), filters out non-tech and malformed entries, classifies them into our 14-track career taxonomy using Gemini, and upserts them directly into the Databricks Delta lakehouse (`workspace.default.opportunities`).
*   **Rule:** Ingestion runs as an independent background pipeline and NEVER runs automatically during user recommendation requests or frontend refreshes.

---

## 3. Current Implementation Status & Pending Work

### A. Swiping & Saves (`/api/swipes` & `/api/saved`)
*   **Status:** Fully implemented and registered.
*   **Endpoints:**
    - `POST /api/swipes` - Record right/left swipe. Right swipe saves, left swipe unsaves.
    - `GET /api/saved` - Return full, deserialized Opportunity objects of saved listings.
    - `POST /api/saved/{opportunity_id}` - Manually save.
    - `DELETE /api/saved/{opportunity_id}` - Manually unsave.
*   **Identity:** Driven purely by `Authorization: Bearer <Firebase ID Token>`. No explicit `student_id` in request paths or bodies.
*   **Frontend Action:** Integrate these endpoints into the UI swipe stack. Ensure retries are safe (operations are idempotent).

### B. Live Databricks Deployment & Schema Migration
*   **Status:** Fully configured and verified with live-compatible Delta DDL.
*   **Script:** `uv run python backend/scripts/migrate_databricks_schema.py`
*   **Details:** Verifies `student_profiles`, `opportunities`, and `career_preferences` tables in `workspace.default`. Safely performs `ALTER TABLE` for any missing columns and sets `active = true` for historical records without dropping data.

---

## 4. Frontend Integration Checklist & Network Setup

1. **Firebase Bearer Token:**
   Every call to `/api/profile/*`, `/api/opportunities/recommendations`, and `/api/agent/*` MUST include `Authorization: Bearer <Firebase ID Token>`.
2. **Local Machine IP for Physical Devices:**
   `http://localhost:8000` only works in the iOS Simulator. For physical iPhone testing over Wi-Fi, change `baseURL` in `APIService.swift` to your machine's LAN IP (e.g., `http://192.168.1.xxx:8000`).
3. **Response Model Decoding:**
   Update `APIService.getRecommendations()` to decode `RecommendationsResponse` rather than flat `[OpportunityCard]`.
4. **Data Models Alignment:**
   - `StudentProfile`: Backend stores `class_year: str` ("Freshman", "Junior", "2027"), while Swift model has `graduationYear: Int`. Align Swift to handle string class year or derive graduation year.
5. **Backend Dependency Decoupling:**
   The frontend communicates strictly with the FastAPI REST API. The frontend never accesses Databricks or Gemini directly.
