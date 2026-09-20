"""Echelon Conversational Agent orchestrator."""

import logging
from typing import Optional

from app.models.student import StudentProfile
from app.models.recommendation import CareerPreferences
from app.services import databricks_service, gemini_service
from pydantic import BaseModel

logger = logging.getLogger(__name__)

class AgentChatRequest(BaseModel):
    message: str

class AgentChatResponse(BaseModel):
    reply: str
    preferences_updated: bool

class AgentServiceError(Exception):
    pass

def handle_chat(uid: str, user_message: str) -> AgentChatResponse:
    """Handles a chat message from the user, updates preferences, and replies."""
    
    # 1. Load context
    profile = databricks_service.get_student_profile(uid)
    if not profile:
        raise AgentServiceError("Student profile not found. Please complete onboarding first.")
        
    preferences = databricks_service.get_career_preferences(uid)
    if not preferences:
        preferences = CareerPreferences()
        
    # 2. Call Gemini Agent with tools
    # We pass the message and context. The agent will respond with a reply
    # and potentially an updated CareerPreferences object.
    update_response = gemini_service.chat_agent(profile, preferences, user_message)
    
    updated = False
    if update_response.updated_preferences:
        # Save to Databricks
        databricks_service.save_career_preferences(uid, update_response.updated_preferences)
        updated = True
        
    return AgentChatResponse(
        reply=update_response.assistant_reply,
        preferences_updated=updated
    )

