from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException, status
from app.api.deps import get_current_user
from app.services.gemini_service import parse_resume, GeminiServiceError
from app.models.student import StudentProfile

router = APIRouter(prefix="/api/profile", tags=["profile"])

@router.post("/parse", response_model=StudentProfile)
async def parse_profile_route(
    resume: UploadFile = File(...),
    bio: str | None = Form(None),
    interests: str | None = Form(None),
    current_user: dict = Depends(get_current_user)
):
    """
    Parse a student's resume PDF (and optional bio/interests) into a structured profile.
    Requires Firebase Authentication.
    """
    if not resume.filename.endswith(".pdf"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Resume must be a PDF file."
        )
        
    try:
        pdf_bytes = await resume.read()
        parsed_profile = parse_resume(pdf_bytes=pdf_bytes, bio=bio, interests=interests)
        return parsed_profile
    except GeminiServiceError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"An unexpected error occurred: {str(e)}"
        )

