import os
from unittest.mock import patch
from app.config import Settings


def test_default_settings():
    """Settings should load with sensible defaults when no env vars are set."""
    settings = Settings()
    assert settings.gemini_api_key is None
    assert settings.databricks_host is None
    assert settings.gemini_generative_model == "gemini-3.8-flash"
    assert settings.gemini_embedding_model == "gemini-embedding-2"
    assert settings.gemini_embedding_dimension == 768


def test_settings_from_env():
    """Settings should pick up environment variables."""
    with patch.dict(os.environ, {
        "GEMINI_API_KEY": "test-key-123",
        "DATABRICKS_HOST": "https://test.databricks.com",
    }):
        settings = Settings()
        assert settings.gemini_api_key == "test-key-123"
        assert settings.databricks_host == "https://test.databricks.com"
