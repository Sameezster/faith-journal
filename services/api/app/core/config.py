"""Application configuration (pydantic-settings).

All secrets come from the environment / Secret Manager. Never commit real keys.
"""
from __future__ import annotations

from functools import lru_cache
from typing import Literal

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # --- App ---
    app_name: str = "Faith Journal API"
    environment: Literal["dev", "staging", "prod"] = "dev"
    api_v1_prefix: str = "/api/v1"
    cors_origins: list[str] = ["*"]

    # --- AI (Gemini is the MVP default; OpenAI addable later) ---
    ai_provider: Literal["gemini", "openai", "keyword"] = "gemini"
    ai_fallback: Literal["keyword"] = "keyword"
    ai_timeout_ms: int = 2500
    ai_max_suggestions: int = 3

    gemini_api_key: str | None = Field(default=None, alias="GEMINI_API_KEY")
    gemini_model: str = "gemini-1.5-flash"
    openai_api_key: str | None = Field(default=None, alias="OPENAI_API_KEY")
    openai_model: str = "gpt-4o-mini"

    # --- Bible ---
    bible_data_dir: str = "data/bibles"
    default_translation: str = "KJV"

    # --- Firebase (token verification) ---
    firebase_project_id: str | None = Field(default=None, alias="FIREBASE_PROJECT_ID")
    # Path to a service-account JSON; if unset in dev, token verification is relaxed.
    google_application_credentials: str | None = Field(
        default=None, alias="GOOGLE_APPLICATION_CREDENTIALS"
    )
    auth_required: bool = False  # set True in staging/prod

    # --- Database (Bible + AI taxonomy/telemetry) ---
    database_url: str = "sqlite+aiosqlite:///./faith_journal.db"


@lru_cache
def get_settings() -> Settings:
    return Settings()
