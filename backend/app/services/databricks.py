"""Databricks service wrapper.

All Databricks interactions go through this module.
Uses the official databricks-sdk.
"""

from databricks.sdk import WorkspaceClient
from databricks.sdk.errors import DatabricksError
from app.config import Settings
import logging

logger = logging.getLogger(__name__)


class DatabricksServiceError(Exception):
    """Raised when a Databricks operation fails."""
    pass


class DatabricksService:
    """Wrapper around the Databricks SDK."""

    def __init__(self, settings: Settings):
        if not settings.databricks_host:
            raise DatabricksServiceError(
                "DATABRICKS_HOST is not configured. "
                "Set it in your .env file or environment variables."
            )
        try:
            kwargs = {"host": settings.databricks_host}
            if settings.databricks_config_profile:
                kwargs["profile"] = settings.databricks_config_profile
            self._client = WorkspaceClient(**kwargs)
            self._warehouse_id = settings.databricks_warehouse_id
            self._catalog = settings.databricks_catalog
            self._schema = settings.databricks_schema
        except Exception as e:
            raise DatabricksServiceError(
                f"Failed to initialize Databricks client: {str(e)}"
            ) from e

    async def test_connection(self) -> dict:
        """Test Databricks connectivity."""
        try:
            # Try listing catalogs as a connectivity test
            catalogs = list(self._client.catalogs.list())
            catalog_names = [c.name for c in catalogs[:5]]
            return {
                "status": "connected",
                "host": self._client.config.host,
                "catalogs": catalog_names,
            }
        except DatabricksError as e:
            raise DatabricksServiceError(
                f"Databricks connection failed: {str(e)}"
            ) from e
        except Exception as e:
            raise DatabricksServiceError(
                f"Databricks connection failed: {str(e)}"
            ) from e

    async def execute_sql(self, statement: str) -> dict:
        """Execute a SQL statement against the configured warehouse."""
        if not self._warehouse_id:
            raise DatabricksServiceError(
                "DATABRICKS_WAREHOUSE_ID is not configured."
            )
        try:
            result = self._client.statement_execution.execute_statement(
                statement=statement,
                warehouse_id=self._warehouse_id,
                catalog=self._catalog,
                schema=self._schema,
            )
            return {
                "status": result.status.state.value if result.status else "unknown",
                "row_count": len(result.result.data_array) if result.result and result.result.data_array else 0,
            }
        except DatabricksError as e:
            raise DatabricksServiceError(
                f"SQL execution failed: {str(e)}"
            ) from e
