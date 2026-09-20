"""Temporary smoke-test route for Databricks workspace connectivity.

Remove or gate behind a feature flag before production.
"""

from fastapi import APIRouter
from pydantic import BaseModel

from app.services.databricks_service import DatabricksServiceError, get_current_user

router = APIRouter(prefix="/test", tags=["test"])


class DatabricksTestResponse(BaseModel):
    status: str
    provider: str
    user: str


@router.get("/databricks", response_model=DatabricksTestResponse)
def test_databricks() -> DatabricksTestResponse:
    """Verify end-to-end connectivity to the Databricks workspace."""
    try:
        user = get_current_user()
        return DatabricksTestResponse(
            status="ok",
            provider="databricks",
            user=user,
        )
    except DatabricksServiceError as exc:
        return DatabricksTestResponse(
            status="error",
            provider="databricks",
            user=str(exc),
        )

