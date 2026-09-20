"""Temporary smoke-test route for Gemini Agent Platform connectivity.

Remove or gate behind a feature flag before production.
"""

from fastapi import APIRouter
from pydantic import BaseModel

from app.services.gemini_service import GeminiServiceError, ping_gemini

router = APIRouter(prefix="/test", tags=["test"])


class GeminiTestResponse(BaseModel):
    status: str
    provider: str
    response: str


@router.get("/gemini", response_model=GeminiTestResponse)
def test_gemini() -> GeminiTestResponse:
    """Verify end-to-end connectivity to the Gemini Agent Platform."""
    try:
        text = ping_gemini()
        return GeminiTestResponse(
            status="ok",
            provider="gemini-agent-platform",
            response=text,
        )
    except GeminiServiceError as exc:
        # Return a structured error body — never expose raw exception details.
        return GeminiTestResponse(
            status="error",
            provider="gemini-agent-platform",
            response=str(exc),
        )

