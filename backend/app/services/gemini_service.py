"""Gemini Enterprise Agent Platform service.

Wraps the google-genai SDK and exposes a single entry point used by route
handlers.  All provider-specific logic lives here; routes stay thin.
"""

from google import genai

from app.core.config import settings


class GeminiServiceError(Exception):
    """Raised when the Gemini service cannot fulfil a request."""


def _get_client() -> genai.Client:
    """Build and return a configured Gemini client.

    Uses the Agent Platform initialisation pattern with an API key.
    Raises GeminiServiceError if the key is absent.
    """
    if settings.google_api_key is None:
        raise GeminiServiceError(
            "GOOGLE_API_KEY is not set. "
            "Add it to your environment or .env file."
        )

    return genai.Client(
        vertexai=True,
        api_key=settings.google_api_key.get_secret_value(),
    )


def ping_gemini() -> str:
    """Send a minimal request to Gemini and return the text response.

    Raises:
        GeminiServiceError: if the key is missing or the provider call fails.
    """
    client = _get_client()
    try:
        response = client.models.generate_content(
            model="gemini-3.5-flash",
            contents="Reply with exactly the word: pong",
        )
        return response.text or ""
    except GeminiServiceError:
        raise
    except Exception as exc:
        # Re-raise without leaking the original exception message
        # (it may contain request details or partial key material).
        raise GeminiServiceError(
            "Gemini provider request failed. Check logs for details."
        ) from exc


from google.genai import types
from app.models.student import StudentProfile

def parse_resume(pdf_bytes: bytes, bio: str | None = None, interests: str | None = None) -> StudentProfile:
    """Parse a resume PDF into a structured profile."""
    client = _get_client()
    
    prompt_parts = [
        "You are an expert career counselor.",
        "Parse the following student resume into a structured profile.",
        "Extract the student's major, class year (e.g. Freshman/Sophomore/Junior/Senior), skills, interests, coursework, and experience."
    ]
    if bio:
        prompt_parts.append(f"Additional Bio provided by student: {bio}")
    if interests:
        prompt_parts.append(f"Additional Interests provided by student: {interests}")
        
    prompt = "\n".join(prompt_parts)
    
    pdf_part = types.Part.from_bytes(data=pdf_bytes, mime_type="application/pdf")
    
    try:
        response = client.models.generate_content(
            model="gemini-3.5-flash",
            contents=[prompt, pdf_part],
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=StudentProfile,
            ),
        )
        return response.parsed
    except GeminiServiceError:
        raise
    except Exception as exc:
        raise GeminiServiceError(f"Failed to parse resume: {str(exc)}") from exc
