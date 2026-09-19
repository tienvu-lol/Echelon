from fastapi import APIRouter, UploadFile, File, Form, Depends, HTTPException
from typing import Optional
from app.config import Settings, get_settings
from app.models.student import StudentProfile
from app.schemas.requests import ProfileCreateRequest

router = APIRouter(prefix="/api", tags=["profile"])


@router.post("/profile/parse", response_model=StudentProfile)
async def parse_profile(
    resume: UploadFile = File(...),
    bio: Optional[str] = Form(None),
    interests: Optional[str] = Form(None),
    settings: Settings = Depends(get_settings),
):
    """Parse a resume PDF and extract a structured student profile.

    Sends the document to Gemini for structured extraction.
    The interests field accepts a comma-separated string.
    """
    # TODO: Implement when Gemini resume parsing is complete
    raise HTTPException(
        status_code=501,
        detail="Resume parsing not yet implemented. This endpoint will use Gemini to extract a structured profile from a resume PDF.",
    )


@router.post("/profile", response_model=StudentProfile)
async def create_profile(
    request: ProfileCreateRequest,
    settings: Settings = Depends(get_settings),
):
    """Create a student profile from structured data.

    Persists the profile to Databricks and generates an embedding.
    """
    # TODO: Persist to Databricks, generate embedding
    profile = StudentProfile(
        major=request.major,
        graduation_year=request.graduation_year,
        skills=request.skills,
        interests=request.interests,
        coursework=request.coursework,
        experience=request.experience,
        bio=request.bio,
    )
    return profile
