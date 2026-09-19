"""Databricks workspace service.

Wraps the Databricks Python SDK (WorkspaceClient) and exposes entry points
used by route handlers.  All provider-specific logic lives here; routes
stay thin.

The SDK is fully synchronous.  FastAPI runs synchronous route handlers in a
thread-pool executor, so blocking calls here are safe as long as the route
handlers themselves are plain ``def`` (not ``async def``).
"""

from databricks.sdk import WorkspaceClient
from databricks.sdk.errors import DatabricksError

from app.core.config import settings


class DatabricksServiceError(Exception):
    """Raised when the Databricks service cannot fulfil a request."""


def _get_client() -> WorkspaceClient:
    """Build and return a configured WorkspaceClient.

    Uses unified authentication via the CLI profile stored in
    ``DATABRICKS_CONFIG_PROFILE``.  No PATs or hardcoded credentials.

    Raises:
        DatabricksServiceError: if the profile name is not configured.
    """
    if not settings.databricks_config_profile:
        raise DatabricksServiceError(
            "DATABRICKS_CONFIG_PROFILE is not set. "
            "Add it to your environment or .env file."
        )

    return WorkspaceClient(profile=settings.databricks_config_profile)


def get_current_user() -> str:
    """Return the display name of the currently authenticated workspace user.

    Performs a minimal read-only call to verify connectivity.

    Raises:
        DatabricksServiceError: if the profile is missing or the call fails.
    """
    client = _get_client()
    try:
        me = client.current_user.me()
        return me.display_name or me.user_name or "unknown"
    except DatabricksServiceError:
        raise
    except DatabricksError as exc:
        # Wrap SDK-specific errors without leaking raw details
        raise DatabricksServiceError(
            "Databricks workspace call failed. Check logs for details."
        ) from exc
    except Exception as exc:
        raise DatabricksServiceError(
            "Databricks provider request failed. Check logs for details."
        ) from exc

