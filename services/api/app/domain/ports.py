"""Ports (interfaces) the application depends on. Adapters live in infrastructure/."""
from __future__ import annotations

from typing import Protocol, runtime_checkable

from app.domain.entities import Book, Chapter, Suggestion, Translation, VerseHit


@runtime_checkable
class AICategorizationProvider(Protocol):
    name: str

    async def suggest(self, text: str, context: str, max_suggestions: int) -> list[Suggestion]:
        """Return category suggestions from the fixed taxonomy. Never raises for empty input."""
        ...


@runtime_checkable
class BibleProvider(Protocol):
    async def list_translations(self) -> list[Translation]: ...
    async def list_books(self, translation: str) -> list[Book]: ...
    async def get_chapter(self, translation: str, book: str, chapter: int) -> Chapter: ...
    async def search(self, query: str, translation: str | None, limit: int) -> list[VerseHit]: ...
