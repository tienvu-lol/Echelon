# API Contracts — Echelon

## Base URL

```
http://localhost:8000
```

---

## Health

### GET /health

Returns server health status.

**Response** `200`
```json
{
  "status": "ok"
}
```

---

## Profile

### POST /api/profile/parse

Parse a resume PDF and extract a structured student profile using Gemini.

**Request**: `multipart/form-data`

| Field | Type | Required | Description |
|---|---|---|---|
| `resume` | File (PDF) | Yes | Resume document |
| `bio` | string | No | Additional bio text |
| `interests` | string | No | Comma-separated interests |

**Response** `200` — `StudentProfile`
```json
{
  "id": "uuid",
  "major": "Computer Science",
  "graduation_year": 2027,
  "skills": ["Python", "TypeScript"],
  "interests": ["AI", "Web Dev"],
  "coursework": ["Data Structures", "ML"],
  "experience": ["Google SWE Intern"],
  "bio": "...",
  "profile_text": "...",
  "created_at": "2026-01-01T00:00:00Z"
}
```

### POST /api/profile

Create a student profile from structured data.

**Request**: `application/json`
```json
{
  "major": "Computer Science",
  "graduation_year": 2027,
  "skills": ["Python"],
  "interests": ["AI"],
  "coursework": [],
  "experience": [],
  "bio": "..."
}
```

**Response** `200` — `StudentProfile` (same as above)

---

## Opportunities

### GET /api/opportunities/recommendations

Get personalized opportunity recommendations for a student.

**Query Parameters**

| Param | Type | Required | Default | Description |
|---|---|---|---|---|
| `student_id` | string | Yes | — | Student UUID |
| `limit` | integer | No | 10 | Max results (1-50) |

**Response** `200`
```json
{
  "student_id": "uuid",
  "opportunities": [
    {
      "id": "uuid",
      "title": "ML Research Assistant",
      "organization": "VT CS Department",
      "opportunity_type": "research",
      "description": "...",
      "skills": ["Python", "NLP"],
      "location": "Blacksburg, VA",
      "paid": true,
      "deadline": "2026-10-15",
      "apply_url": "https://...",
      "explanation": "This matches your NLP coursework and Python skills..."
    }
  ]
}
```

---

## Swipes

### POST /api/swipes

Record a swipe on an opportunity.

**Request**: `application/json`
```json
{
  "student_id": "uuid",
  "opportunity_id": "uuid",
  "direction": "right"
}
```

**Response** `200`
```json
{
  "id": "uuid",
  "student_id": "uuid",
  "opportunity_id": "uuid",
  "direction": "right",
  "created_at": "2026-01-01T00:00:00Z"
}
```

---

## Saved

### GET /api/saved

Get all saved opportunities for a student.

**Query Parameters**

| Param | Type | Required | Description |
|---|---|---|---|
| `student_id` | string | Yes | Student UUID |

**Response** `200`
```json
{
  "student_id": "uuid",
  "opportunities": []
}
```

### POST /api/saved/{opportunity_id}

Explicitly save an opportunity.

**Query Parameters**

| Param | Type | Required | Description |
|---|---|---|---|
| `student_id` | string | Yes | Student UUID |

**Response** `200`
```json
{
  "student_id": "uuid",
  "opportunity_id": "uuid",
  "created_at": "2026-01-01T00:00:00Z"
}
```
