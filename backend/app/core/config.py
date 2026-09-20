"""Application configuration loaded from environment variables."""

from pathlib import Path

from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict

# Resolve the repo-root .env regardless of the process working directory.
# This file lives at  backend/app/core/config.py
# parents[0] → backend/app/core/
# parents[1] → backend/app/
# parents[2] → backend/
# parents[3] → Echelon/  (repo root)
_REPO_ROOT = Path(__file__).resolve().parents[3]
_ENV_FILE = _REPO_ROOT / ".env"


class Settings(BaseSettings):
    """Top-level settings for the Echelon backend.

    Values are read from environment variables first, then from the
    repository-root ``.env`` file.  The path is resolved from this file's
    location so it is stable regardless of the process working directory.
    No secrets are hard-coded here.
    """

    model_config = SettingsConfigDict(
        env_file=str(_ENV_FILE),
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # Application
    app_name: str = "Echelon Backend"
    debug: bool = False

    # Gemini / Google Cloud Agent Platform
    # Populated from GOOGLE_API_KEY environment variable.
    # Optional so the server starts cleanly even without the key set;
    # the Gemini service raises an explicit error at call-time instead.
    google_api_key: SecretStr | None = None
    gemini_api_key: str | None = None
    gemini_generative_model: str = "gemini-3.8-flash"
    gemini_embedding_model: str = "gemini-embedding-2"
    gemini_embedding_dimension: int = 768

    # Firebase Authentication
    firebase_credentials_path: str | None = None

    # Databricks
    # Name of the CLI profile in ~/.databrickscfg to use for unified auth.
    databricks_host: str | None = None
    databricks_config_profile: str | None = None
    databricks_warehouse_id: str | None = None
    databricks_catalog: str | None = None
    databricks_schema: str | None = None
    databricks_ai_search_endpoint: str | None = None
    databricks_ai_search_index: str | None = None


from functools import lru_cache


@lru_cache
def get_settings() -> Settings:
    """Return a cached Settings instance."""
    return Settings()


settings = Settings()
