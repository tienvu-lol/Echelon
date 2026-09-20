# Echelon: Frontend & Backend Integration Status

This document outlines the current state of the Echelon FastAPI backend, detailing what is fully implemented and ready for frontend integration, versus what is still pending or required from the frontend team.

---

## 1. Authentication Flow (Crucial for Frontend)

The backend now uses **Firebase Authentication** as the absolute source of truth for identity. 

**Frontend Responsibilities:**
1. The iOS/Expo app must handle user login/signup using the Firebase Client SDK.
2. The app must retrieve the user's **Firebase ID Token**.
3. **Every authenticated API request** must include this token in the header:
   `Authorization: Bearer <FIREBASE_ID_TOKEN>`

*Note: The backend no longer requires you to pass `uid` in the query parameters or request body. The backend automatically extracts the verified `uid` securely from the Bearer token.*

---

## 2. What the Backend Currently Offers (Ready to Use)

The core recommendation logic, LLM sandboxing, and database engines have been implemented. The following endpoints are live in the development server:

### A. Echelon Agent Chat
*   **Endpoint:** `POST /api/agent/chat`
*   **Headers:** `Authorization: Bearer <token>`
*   **Request Body:**
    ```json
    { "message": "I'm looking for a data science internship in New York." }
    ```
*   **Response:**
    ```json
    {
      "reply": "I'd love to help! I've updated your career preferences to focus on Data Science roles in New York.",
      "updated_preferences": true
    }
    ```
*   **Backend Magic:** This isn't just a chatbot. It is wrapped in a strict safety harness. It reads the user's current Databricks profile, restricts conversation to career topics, and automatically updates their Databricks `CareerPreferences` in the background based on the conversation.

### B. Opportunity Recommendations
*   **Endpoint:** `GET /api/opportunities/recommendations?limit=10`
*   **Headers:** `Authorization: Bearer <token>`
*   **Response:** Returns a ranked list of `OpportunityCard` models.
*   **Backend Magic:** This triggers a 3-step pipeline:
    1. Evaluates strict eligibility (graduation year, VT student status).
    2. Runs a deterministic heuristic engine to find the top 40 matches based on the user's Databricks profile (skills, tracks, interests).
    3. Passes the candidates to the **Gemini Reranker Engine**, which scores them out of 100 and generates a personalized explanation for *why* the user is a good fit.
*   **Headers:** `Authorization: Bearer <Firebase ID Token>`
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
            "description": "...",
            "source_url": "https://cs.vt.edu/opp/001",
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
          "eligibility_notes": []
        }
      ]
    }
    ```
*   **iOS Contract Note:** Swift `APIService.swift` currently expects a flat `[OpportunityCard]` array with `.explanation`. The frontend model must be updated to decode the nested `RecommendationsResponse` schema where the opportunity is nested under `.opportunity` and the rationale is in `.match_reason`.
*   **Backend Pipeline:**
    1. Reads the authenticated student's profile and career preferences from Databricks.
    2. Retrieves active candidates (`databricks_service.get_active_opportunities()`).
    3. Evaluates strict eligibility constraints (academic standing, work authorization).
    4. Deterministic heuristic ranking (track overlap, skill overlap, interest overlap).
    5. Gemini LLM reranking and personalized match reason generation.

### C. Ingestion Ecosystem (Offline/Background)
*   The backend currently has web scrapers (like `SimplifyJobsAdapter`) that pull hundreds of internships, pass them through strict Tech/CS quality filters, and classify them into a 14-track taxonomy using Gemini. 
### C. Ingestion Ecosystem (Offline / Background)
*   **Script:** `uv run python backend/scripts/run_ingestion.py [--max-items 25]`
*   Scrapes verified listings via source adapters (e.g., `SimplifyJobsAdapter`), filters out non-tech and malformed entries, classifies them into our 14-track career taxonomy using Gemini, and upserts them directly into the Databricks Delta lakehouse (`workspace.default.opportunities`).
*   **Rule:** Ingestion runs as an independent background pipeline and NEVER runs automatically during user recommendation requests or frontend refreshes.

---

## 3. What is in Demand (Pending / Work in Progress)
## 3. Current Implementation Status & Pending Work

While the core AI and orchestration logic is complete, there are a few final endpoints that still need to be "wired up" to the database before the frontend can fully utilize them.
### A. Resume Upload & Profile Parsing (`POST /api/profile/parse`)
*   **Status:** Implemented on backend.
*   **Details:** Accepts `multipart/form-data` with `resume` (PDF file) plus optional `bio` and `interests` strings. Uses Gemini 3.8 Flash multimodal API to parse into `StudentProfile` and stores it into `workspace.default.student_profiles`.
*   **Frontend Action:** Swift view should submit `multipart/form-data` containing the PDF data with Bearer token.

### A. Resume Upload & Profile Parsing (`/api/profile/parse`)
*   **Status:** Endpoint exists, but logic is stubbed out.
*   **In Demand:** The backend needs to finish wiring up the multimodal PDF processing so Gemini can extract the raw resume bytes into our structured `StudentProfile` model. 
*   **Frontend Action:** Be prepared to send a `multipart/form-data` request containing the PDF file.

### B. Swiping & Saves (`/api/swipes`)
*   **Status:** Endpoint exists, but Databricks persistence is stubbed out.
*   **In Demand:** The backend needs to write the `MERGE INTO` SQL statements to save right/left swipes and update the user's preference weights dynamically based on what they swipe on.
*   **Frontend Action:** Build the Tinder-style swipe UI and fire a background `POST /api/swipes` request (`{ "opportunity_id": "123", "direction": "right" }`) on every card swipe.
*   **Status:** Stubbed & Unregistered.
*   **Details:** The route definitions in `backend/app/api/swipes.py` are currently unregistered in `main.py`, and database persistence is marked as `# TODO: Persist to Databricks`.
*   **Frontend Action:** Do not rely on swipe persistence in production yet. Post-merge task will register the router, inject `get_current_user` auth, and add Databricks swipe tables.

### C. Live Databricks Deployment
*   **Status:** The backend has all the `CREATE TABLE` and `MERGE INTO` logic written perfectly.
*   **In Demand:** The backend team needs to run the initial table deployment script against the live Databricks SQL Warehouse to instantiate the database. Until this happens, API calls will fail when attempting to read/write real data.
### C. Live Databricks Deployment & Migration
*   **Status:** Fully configured and verified with live-compatible Delta DDL.
*   **Script:** `uv run python backend/scripts/migrate_databricks_schema.py`
*   **Details:** Verifies `student_profiles`, `opportunities`, and `career_preferences` tables in `workspace.default`. Safely performs `ALTER TABLE` for any missing Phase 2 columns and sets `active = true` for historical records without dropping data.

---

## Summary for Frontend Developer
1. Set up your global `fetch` / Axios wrapper to inject the Firebase ID Token into the `Authorization` header.
2. You can begin building the **Agent Chat** screen and the **Discover (Swipe)** screens immediately against the local development server.
3. Ignore Databricks setup—that is purely a backend concern. Your only interface is the FastAPI REST endpoints.
## 4. Frontend Integration Checklist & Network Setup

1. **Firebase Bearer Token:**
   Every call to `/api/profile/*`, `/api/opportunities/recommendations`, and `/api/agent/*` MUST include `Authorization: Bearer <Firebase ID Token>`.
2. **Local Machine IP for Physical Devices:**
   `http://localhost:8000` only works in the iOS Simulator. For physical iPhone testing over Wi-Fi, change `baseURL` in `APIService.swift` to your machine's LAN IP (e.g., `http://192.168.1.xxx:8000`).
3. **Response Model Decoding:**
   Update `APIService.getRecommendations()` to decode `RecommendationsResponse` rather than flat `[OpportunityCard]`.
4. **Data Models Alignment:**
   - `StudentProfile`: Backend stores `class_year: str` ("Freshman", "Junior"), while Swift model has `graduationYear: Int`. Align Swift to handle string class year or derive graduation year.

