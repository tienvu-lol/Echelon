from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache
from typing import Optional

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    gemini_api_key: Optional[str] = None
    gemini_generative_model: str = "gemini-3.8-flash"
    gemini_embedding_model: str = "gemini-embedding-2"
    gemini_embedding_dimension: int = 768

    databricks_host: Optional[str] = None
    databricks_config_profile: Optional[str] = None
    databricks_warehouse_id: Optional[str] = None
    databricks_catalog: Optional[str] = None
    databricks_schema: Optional[str] = None
    databricks_ai_search_endpoint: Optional[str] = None
    databricks_ai_search_index: Optional[str] = None

@lru_cache
def get_settings() -> Settings:
    return Settings()
