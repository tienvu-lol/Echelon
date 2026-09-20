from fastapi import APIRouter, Depends, HTTPException

from app.api.deps import get_current_user
from app.services.echelon_agent_service import handle_chat, AgentChatRequest, AgentChatResponse, AgentServiceError

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
    try:
        uid = current_user.get("uid")
        response = handle_chat(uid, request.message)
        return response
    except AgentServiceError as e:
        raise HTTPException(
            status_code=400,
            detail=str(e),
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Internal Server Error: {str(e)}",
        )
