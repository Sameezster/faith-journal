"""Use-cases for Bible reading & search (delegate to a BibleProvider port)."""
from __future__ import annotations

from app.domain.ports import BibleProvider


class ListTranslationsUseCase:
    def __init__(self, provider: BibleProvider) -> None:
        self._p = provider

    async def execute(self):
        return await self._p.list_translations()


class ListBooksUseCase:
    def __init__(self, provider: BibleProvider) -> None:
        self._p = provider

    async def execute(self, translation: str):
        return await self._p.list_books(translation)


class GetChapterUseCase:
    def __init__(self, provider: BibleProvider) -> None:
        self._p = provider

    async def execute(self, translation: str, book: str, chapter: int):
        return await self._p.get_chapter(translation, book, chapter)


class SearchVersesUseCase:
    def __init__(self, provider: BibleProvider) -> None:
        self._p = provider

    async def execute(self, query: str, translation: str | None, limit: int):
        return await self._p.search(query, translation, limit)
