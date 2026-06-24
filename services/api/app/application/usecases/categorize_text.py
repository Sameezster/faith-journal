"""Use-case: suggest categories for a piece of text (verse/reflection/prayer)."""
from __future__ import annotations

from dataclasses import dataclass

from app.domain.entities import Suggestion
from app.infrastructure.ai.factory import CategorizationService


@dataclass
class CategorizeResult:
    suggestions: list[Suggestion]
    provider: str
    fallback_used: bool


class CategorizeTextUseCase:
    def __init__(self, service: CategorizationService) -> None:
        self._service = service

    async def execute(self, text: str, context: str, max_suggestions: int) -> CategorizeResult:
        suggestions, provider, fallback = await self._service.categorize(
            text=text, context=context, max_suggestions=max_suggestions
        )
        return CategorizeResult(suggestions=suggestions, provider=provider, fallback_used=fallback)
