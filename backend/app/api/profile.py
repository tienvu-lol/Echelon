from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status

from app.api.deps import get_current_user
from app.models.student import StudentProfile
from app.schemas.requests import ProfileCreateRequest
from app.services.databricks_service import (
    DatabricksServiceError,
    get_student_profile,
    save_student_profile,
)
from app.services.gemini_service import GeminiServiceError, parse_resume

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
                status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found."
            )
        return profile
    except DatabricksServiceError:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve profile.",
        )


@router.post("/parse", response_model=StudentProfile)
async def parse_profile_route(
    resume: UploadFile = File(...),
    bio: str | None = Form(None),
    interests: str | None = Form(None),
    current_user: dict = Depends(get_current_user),
):
    """
    Parse a student's resume PDF (and optional bio/interests) into a structured profile,
    and persist it to Databricks keyed by the user's Firebase UID.
    Requires Firebase Authentication.
    """
    if not resume.filename.endswith(".pdf"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Resume must be a PDF file."
        )

    uid = current_user.get("uid")
    if not uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid user token."
        )

    try:
        pdf_bytes = await resume.read()
        parsed_profile = parse_resume(pdf_bytes=pdf_bytes, bio=bio, interests=interests)

        # Persist to Databricks
        save_student_profile(uid, parsed_profile)

        return parsed_profile
    except GeminiServiceError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )
    except DatabricksServiceError:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Profile parsed but failed to save to Databricks.",
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"An unexpected error occurred: {e!s}",
        )


@router.post("", response_model=StudentProfile)
async def create_profile(
    request: ProfileCreateRequest, current_user: dict = Depends(get_current_user)
):
    """
    Manually create or update a student profile without uploading a resume.
    """
    uid = current_user.get("uid")
    if not uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid user token."
        )

    profile = StudentProfile(
        major=request.major,
        class_year=str(
            request.graduation_year
        ),  # map int graduation_year to class_year string temporarily or explicitly
        skills=request.skills,
        interests=request.interests,
        coursework=request.coursework,
        experience=request.experience,
        bio=request.bio,
    )

    try:
        save_student_profile(uid, profile)
        return profile
    except DatabricksServiceError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to save profile: {e!s}",
        )
