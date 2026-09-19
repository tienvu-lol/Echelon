# Backend API

Base URL:
`http://localhost:8000`

## GET /health

Response:

{
  "status": "ok"
}

## POST /profiles/parse

Accepts:
multipart/form-data

Fields:
- resume: PDF file
- bio: optional string
- interests: optional string

Returns:

{
  "major": "Computer Science",
  "year": "Sophomore",
  "skills": ["Python", "Java"],
  "interests": ["AI", "Cybersecurity"],
  "coursework": ["Data Structures"],
  "experience": []
}

## GET /opportunities/recommendations

Query:
student_id

Returns:

[
  {
    "id": "...",
    "title": "...",
    "organization": "...",
    "description": "...",
    "match_reason": "...",
    "source_url": "...",
    "contact_email": null
  }
]

---

## Domain Models

These models describe the canonical JSON structure used internally and
returned by API endpoints.  They are defined in `backend/app/models/`.

### StudentProfile

`backend/app/models/student.py`

```json
{
  "major":      "Computer Science",
  "class_year": "Sophomore",
  "bio":        "Optional free-text bio.",
  "skills":     ["Python", "Java"],
  "interests":  ["AI", "Cybersecurity"],
  "coursework": ["Data Structures"],
  "experience": ["SWE Intern @ Acme"]
}
```

| Field        | Type           | Required | Notes            |
|--------------|----------------|----------|------------------|
| `major`      | string or null | No       |                  |
| `class_year` | string or null | No       |                  |
| `bio`        | string or null | No       |                  |
| `skills`     | list[string]   | No       | Defaults to `[]` |
| `interests`  | list[string]   | No       | Defaults to `[]` |
| `coursework` | list[string]   | No       | Defaults to `[]` |
| `experience` | list[string]   | No       | Defaults to `[]` |

---

### Opportunity

`backend/app/models/opportunity.py`

```json
{
  "id":               "opp-001",
  "title":            "Research Assistant",
  "organization":     "VT CS Department",
  "opportunity_type": "research",
  "description":      "Work on ML research.",
  "source_url":       "https://example.vt.edu/opp/001",

  "skills":           ["Python"],
  "interests":        ["AI"],
  "eligibility":      ["Undergraduate"],
  "majors":           ["Computer Science"],
  "class_years":      ["Sophomore", "Junior"],

  "location":         "Blacksburg, VA",
  "time_commitment":  "10 hrs/week",
  "compensation":     "Unpaid",
  "deadline":         "2026-12-01",
  "apply_url":        "https://example.vt.edu/apply/001",
  "contact_name":     null,
  "contact_email":    null
}
```

| Field              | Type           | Required | Notes                                          |
|--------------------|----------------|----------|------------------------------------------------|
| `id`               | string         | **Yes**  |                                                |
| `title`            | string         | **Yes**  |                                                |
| `organization`     | string         | **Yes**  |                                                |
| `opportunity_type` | string         | **Yes**  | e.g. research, job, club, scholarship          |
| `description`      | string         | **Yes**  |                                                |
| `source_url`       | string         | **Yes**  | Canonical link to opportunity listing          |
| `skills`           | list[string]   | No       | Defaults to `[]`                               |
| `interests`        | list[string]   | No       | Defaults to `[]`                               |
| `eligibility`      | list[string]   | No       | Defaults to `[]`                               |
| `majors`           | list[string]   | No       | Defaults to `[]`                               |
| `class_years`      | list[string]   | No       | Defaults to `[]`                               |
| `location`         | string or null | No       |                                                |
| `time_commitment`  | string or null | No       |                                                |
| `compensation`     | string or null | No       |                                                |
| `deadline`         | string or null | No       | ISO 8601 date string                           |
| `apply_url`        | string or null | No       |                                                |
| `contact_name`     | string or null | No       | Never fabricated - only from real data         |
| `contact_email`    | string or null | No       | Never fabricated - only from real data         |
