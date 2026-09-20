"""FastAPI application entry point."""

from fastapi import FastAPI

from app.api.auth import router as auth_router
from app.api.health import router as health_router
from app.api.profile import router as profile_router
from app.api.test_databricks_route import router as test_databricks_router
from app.api.test_gemini_route import router as test_gemini_router
from app.core.config import settings

app = FastAPI(
    title=settings.app_name,
    debug=settings.debug,
)

app.include_router(health_router)
app.include_router(test_gemini_router)
app.include_router(profile_router)
app.include_router(test_databricks_router)
app.include_router(auth_router)

from app.api.agent import router as agent_router
from app.api.opportunities import router as opportunities_router
from app.api.swipes import router as swipes_router

app.include_router(opportunities_router)
app.include_router(agent_router)
app.include_router(swipes_router)
