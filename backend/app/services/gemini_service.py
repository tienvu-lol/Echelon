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

