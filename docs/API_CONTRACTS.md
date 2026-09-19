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