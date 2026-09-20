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

### C. Ingestion Ecosystem (Offline/Background)
*   The backend currently has web scrapers (like `SimplifyJobsAdapter`) that pull hundreds of internships, pass them through strict Tech/CS quality filters, and classify them into a 14-track taxonomy using Gemini. 

---

## 3. What is in Demand (Pending / Work in Progress)

While the core AI and orchestration logic is complete, there are a few final endpoints that still need to be "wired up" to the database before the frontend can fully utilize them.

### A. Resume Upload & Profile Parsing (`/api/profile/parse`)
*   **Status:** Endpoint exists, but logic is stubbed out.
*   **In Demand:** The backend needs to finish wiring up the multimodal PDF processing so Gemini can extract the raw resume bytes into our structured `StudentProfile` model. 
*   **Frontend Action:** Be prepared to send a `multipart/form-data` request containing the PDF file.

### B. Swiping & Saves (`/api/swipes`)
*   **Status:** Endpoint exists, but Databricks persistence is stubbed out.
*   **In Demand:** The backend needs to write the `MERGE INTO` SQL statements to save right/left swipes and update the user's preference weights dynamically based on what they swipe on.
*   **Frontend Action:** Build the Tinder-style swipe UI and fire a background `POST /api/swipes` request (`{ "opportunity_id": "123", "direction": "right" }`) on every card swipe.

### C. Live Databricks Deployment
*   **Status:** The backend has all the `CREATE TABLE` and `MERGE INTO` logic written perfectly.
*   **In Demand:** The backend team needs to run the initial table deployment script against the live Databricks SQL Warehouse to instantiate the database. Until this happens, API calls will fail when attempting to read/write real data.

---

## Summary for Frontend Developer
1. Set up your global `fetch` / Axios wrapper to inject the Firebase ID Token into the `Authorization` header.
2. You can begin building the **Agent Chat** screen and the **Discover (Swipe)** screens immediately against the local development server.
3. Ignore Databricks setup—that is purely a backend concern. Your only interface is the FastAPI REST endpoints.

