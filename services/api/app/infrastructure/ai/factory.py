"""Builds the active AI provider and wires the fallback chain."""
from __future__ import annotations

import asyncio
import logging

from app.core.config import Settings
from app.infrastructure.ai.gemini_provider import GeminiProvider
from app.infrastructure.ai.keyword_provider import KeywordRuleProvider
from app.infrastructure.ai.openai_provider import OpenAIProvider

log = logging.getLogger(__name__)


class CategorizationService:
    """Runs the primary provider, then falls back to keyword. Never hard-fails."""

    def __init__(self, settings: Settings) -> None:
        self._settings = settings
        self._keyword = KeywordRuleProvider()
        self._primary = self._build_primary(settings)

    @staticmethod
    def _build_primary(s: Settings):
        if s.ai_provider == "gemini" and s.gemini_api_key:
            return GeminiProvider(s.gemini_api_key, s.gemini_model)
        if s.ai_provider == "openai" and s.openai_api_key:
            return OpenAIProvider(s.openai_api_key, s.openai_model)
        return None  # no key configured -> keyword only

    async def categorize(self, text: str, context: str, max_suggestions: int):
        if self._primary is not None:
            try:
                timeout = self._settings.ai_timeout_ms / 1000
                suggestions = await asyncio.wait_for(
                    self._primary.suggest(text, context, max_suggestions), timeout=timeout
                )
                if suggestions:
                    return suggestions, self._primary.name, False
            except (asyncio.TimeoutError, Exception) as exc:  # noqa: BLE001
                log.warning("AI provider '%s' failed, using keyword fallback: %s",
                            getattr(self._primary, "name", "?"), exc)
        suggestions = await self._keyword.suggest(text, context, max_suggestions)
        return suggestions, self._keyword.name, True
