from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env", env_file_encoding="utf-8", extra="ignore"
    )

    gemini_api_key: str | None = None
    gemini_generative_model: str = "gemini-3.8-flash"
    gemini_embedding_model: str = "gemini-embedding-2"
    gemini_embedding_dimension: int = 768

    databricks_host: str | None = None
    databricks_config_profile: str | None = None
    databricks_warehouse_id: str | None = None
    databricks_catalog: str | None = None
    databricks_schema: str | None = None
    databricks_ai_search_endpoint: str | None = None
    databricks_ai_search_index: str | None = None


@lru_cache
def get_settings() -> Settings:
    return Settings()
