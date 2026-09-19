from fastapi import APIRouter, Depends
from app.config import Settings, get_settings
from app.schemas.responses import HealthResponse, ServiceTestResponse

router = APIRouter()


@router.get("/health", response_model=HealthResponse)
async def health_check():
    return HealthResponse(status="ok")


@router.get("/api/test/gemini", response_model=ServiceTestResponse)
async def test_gemini(settings: Settings = Depends(get_settings)):
    """Test Gemini API connectivity. Requires GEMINI_API_KEY."""
    from app.services.gemini import GeminiService, GeminiServiceError
    try:
        service = GeminiService(settings)
        result = await service.test_connection()
        return ServiceTestResponse(
            service="gemini",
            status="ok",
            message="Gemini API is reachable",
            details=result,
        )
    except GeminiServiceError as e:
        return ServiceTestResponse(
            service="gemini",
            status="error",
            message=str(e),
        )


@router.get("/api/test/databricks", response_model=ServiceTestResponse)
async def test_databricks(settings: Settings = Depends(get_settings)):
    """Test Databricks connectivity. Requires Databricks configuration."""
    from app.services.databricks import DatabricksService, DatabricksServiceError
    try:
        service = DatabricksService(settings)
        result = await service.test_connection()
        return ServiceTestResponse(
            service="databricks",
            status="ok",
            message="Databricks is reachable",
            details=result,
        )
    except DatabricksServiceError as e:
        return ServiceTestResponse(
            service="databricks",
            status="error",
            message=str(e),
        )
