"""Gemini API service wrapper.

All Gemini API interactions go through this module.
Uses the google-genai SDK (NOT google-generativeai).
"""

from google import genai
from google.genai import types, errors
from app.config import Settings
from app.models.student import StudentProfile
import logging

logger = logging.getLogger(__name__)


class GeminiServiceError(Exception):
    """Raised when a Gemini API call fails."""
    pass


class GeminiService:
    """Wrapper around the Google Gemini API."""

    def __init__(self, settings: Settings):
        if not settings.gemini_api_key:
            raise GeminiServiceError(
                "GEMINI_API_KEY is not configured. "
                "Set it in your .env file or environment variables."
            )
        self._client = genai.Client(api_key=settings.gemini_api_key)
        self._generative_model = settings.gemini_generative_model
        self._embedding_model = settings.gemini_embedding_model
        self._embedding_dimension = settings.gemini_embedding_dimension

    async def test_connection(self) -> dict:
        """Test Gemini API connectivity with a simple request."""
        try:
            response = self._client.models.generate_content(
                model=self._generative_model,
                contents="Respond with exactly: {\"status\": \"connected\"}",
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                ),
            )
            return {
                "status": "connected",
                "model": self._generative_model,
                "response": response.text,
            }
        except errors.APIError as e:
            raise GeminiServiceError(f"Gemini API error: {e.message}") from e
        except Exception as e:
            raise GeminiServiceError(f"Gemini connection failed: {str(e)}") from e

    async def generate_embedding(self, text: str) -> list[float]:
        """Generate a vector embedding for the given text."""
        try:
            response = self._client.models.embed_content(
                model=self._embedding_model,
                contents=text,
                config=types.EmbedContentConfig(
                    output_dimensionality=self._embedding_dimension,
                ),
            )
            return response.embeddings[0].values
        except errors.APIError as e:
            raise GeminiServiceError(f"Embedding generation failed: {e.message}") from e
        except Exception as e:
            raise GeminiServiceError(f"Embedding generation failed: {str(e)}") from e

    async def parse_resume(self, pdf_bytes: bytes, bio: str | None = None, interests: list[str] | None = None) -> StudentProfile:
        """Parse a resume PDF and extract a structured student profile.

        This is a skeleton — full implementation will use multimodal input
        with the PDF bytes sent as a document part.
        """
        # TODO: Implement full resume parsing with PDF upload
        # For now, use text-based extraction as a placeholder
        prompt_parts = ["Extract a student profile from the following resume information."]
        if bio:
            prompt_parts.append(f"Bio: {bio}")
        if interests:
            prompt_parts.append(f"Interests: {', '.join(interests)}")
        prompt_parts.append("Return a structured JSON profile.")

        try:
            response = self._client.models.generate_content(
                model=self._generative_model,
                contents="\n".join(prompt_parts),
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    response_json_schema=StudentProfile.model_json_schema(),
                ),
            )
            return StudentProfile.model_validate_json(response.text)
        except errors.APIError as e:
            raise GeminiServiceError(f"Resume parsing failed: {e.message}") from e
        except Exception as e:
            raise GeminiServiceError(f"Resume parsing failed: {str(e)}") from e
