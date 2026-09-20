import logging

from fastapi import APIRouter, Depends, HTTPException, status

from app.api.deps import get_current_user
from app.services.databricks_service import DatabricksServiceError
from app.services.echelon_agent_service import (
    AgentChatRequest,
    AgentChatResponse,
    AgentServiceError,
    handle_chat,
)
from app.services.gemini_service import GeminiServiceError

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/agent", tags=["agent"])


@router.post("/chat", response_model=AgentChatResponse)
async def chat_with_agent(
    request: AgentChatRequest,
    current_user: dict = Depends(get_current_user),
):
    """Conversational endpoint for Echelon Agent.

    Receives a user message, processes it via Gemini with strict safety harness,
    updates Databricks CareerPreferences if new context is learned, and returns
    the assistant's reply.
    """
    uid = current_user.get("uid")
    if not uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid user token.",
        )

    try:
        response = handle_chat(uid, request.message)
        return response
    except AgentServiceError as e:
        logger.warning("Agent validation error for uid %s: %s", uid, e)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )
    except (DatabricksServiceError, GeminiServiceError) as e:
        logger.error("Provider failure in chat_with_agent for uid %s: %s", uid, e, exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to process chat request.",
        )
    except Exception as e:
        logger.error("Unexpected error in chat_with_agent for uid %s: %s", uid, e, exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error.",
        )
