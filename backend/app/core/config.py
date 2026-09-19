"""Application configuration loaded from environment variables."""

from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Top-level settings for the Echelon backend.

    Values are read from environment variables first, then from a `.env`
    file located in the working directory (if present).  No secrets are
    hard-coded here.
    """

    model_config = SettingsConfigDict(
        env_file=("../.env", ".env"),
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # Application
    app_name: str = "Echelon Backend"
    debug: bool = False

    # Future: add GEMINI_API_KEY, DATABRICKS_* etc. here when needed.
    # Gemini / Google Cloud Agent Platform
    # Populated from GOOGLE_API_KEY environment variable.
    # Optional so the server starts cleanly even without the key set;
    # the Gemini service raises an explicit error at call-time instead.
    google_api_key: SecretStr | None = None

    # Firebase Authentication
    firebase_credentials_path: str | None = None


settings = Settings()

