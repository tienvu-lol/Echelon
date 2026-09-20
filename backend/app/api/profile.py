from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException, status
from app.api.deps import get_current_user
from app.services.gemini_service import parse_resume, GeminiServiceError
from app.services.databricks_service import save_student_profile, get_student_profile, DatabricksServiceError
from app.models.student import StudentProfile

router = APIRouter(prefix="/api/profile", tags=["profile"])

@router.get("/me", response_model=StudentProfile)
async def get_my_profile(current_user: dict = Depends(get_current_user)):
    """
    Retrieve the authenticated user's profile from Databricks.
    """
    uid = current_user.get("uid")
    try:
        profile = get_student_profile(uid)
        if not profile:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Profile not found."
            )
        return profile
    except DatabricksServiceError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve profile."
        )

@router.post("/parse", response_model=StudentProfile)
async def parse_profile_route(
    resume: UploadFile = File(...),
    bio: str | None = Form(None),
    interests: str | None = Form(None),
    current_user: dict = Depends(get_current_user)
):
    """
    Parse a student's resume PDF (and optional bio/interests) into a structured profile,
    and persist it to Databricks keyed by the user's Firebase UID.
    Requires Firebase Authentication.
    """
    if not resume.filename.endswith(".pdf"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Resume must be a PDF file."
        )
        
    uid = current_user.get("uid")
    if not uid:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid user token.")
        
    try:
        pdf_bytes = await resume.read()
        parsed_profile = parse_resume(pdf_bytes=pdf_bytes, bio=bio, interests=interests)
        
        # Persist to Databricks
        save_student_profile(uid, parsed_profile)
        
        return parsed_profile
    except GeminiServiceError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
    except DatabricksServiceError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Profile parsed but failed to save to Databricks."
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"An unexpected error occurred: {str(e)}"
        )

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
