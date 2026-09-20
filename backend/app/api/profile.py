import logging

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

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/profile", tags=["profile"])


@router.get("/me", response_model=StudentProfile)
async def get_my_profile(current_user: dict = Depends(get_current_user)):
    """
    Retrieve the authenticated user's profile from Databricks.
    """
    uid = current_user.get("uid")
    if not uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid user token."
        )
    try:
        profile = get_student_profile(uid)
        if not profile:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found."
            )
        return profile
    except HTTPException:
        raise
    except DatabricksServiceError as e:
        logger.error("Databricks error in get_my_profile for uid %s: %s", uid, e, exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve profile.",
        )
    except Exception as e:
        logger.error("Unexpected error in get_my_profile for uid %s: %s", uid, e, exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error.",
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
        logger.info("Authenticated Firebase UID for profile save: %s", uid)
        save_student_profile(uid, parsed_profile)
        logger.info("Successfully persisted profile for Firebase UID: %s", uid)

        return parsed_profile
    except GeminiServiceError as e:
        logger.error("Gemini error parsing resume for uid %s: %s", uid, e, exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to parse resume with AI service.",
        )
    except DatabricksServiceError as e:
        logger.error("Databricks error saving parsed profile for uid %s: %s", uid, e, exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Profile parsed but failed to save to Databricks.",
        )
    except Exception as e:
        logger.error("Unexpected error in parse_profile for uid %s: %s", uid, e, exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An unexpected error occurred while processing profile.",
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
        logger.info("Authenticated Firebase UID for profile save: %s", uid)
        save_student_profile(uid, profile)
        logger.info("Successfully persisted profile for Firebase UID: %s", uid)
        return profile
    except DatabricksServiceError as e:
        logger.error("Databricks error saving profile for uid %s: %s", uid, e, exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to save profile.",
        )
    except Exception as e:
        logger.error("Unexpected error creating profile for uid %s: %s", uid, e, exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error.",
        )
