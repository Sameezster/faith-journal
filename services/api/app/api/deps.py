"""Dependency wiring (composition root) for the API layer."""
from __future__ import annotations

from functools import lru_cache

from fastapi import Depends, Header

from app.application.usecases.bible_usecases import (
    GetChapterUseCase, ListBooksUseCase, ListTranslationsUseCase, SearchVersesUseCase,
)
from app.application.usecases.categorize_text import CategorizeTextUseCase
from app.core.config import Settings, get_settings
from app.infrastructure.ai.factory import CategorizationService
from app.infrastructure.bible.local_bundled_provider import LocalBundledProvider
from app.infrastructure.firebase.token_verifier import FirebaseTokenVerifier


@lru_cache
def _categorization_service() -> CategorizationService:
    return CategorizationService(get_settings())


@lru_cache
def _bible_provider() -> LocalBundledProvider:
    return LocalBundledProvider(get_settings().bible_data_dir)


@lru_cache
def _verifier() -> FirebaseTokenVerifier:
    return FirebaseTokenVerifier(get_settings())


def get_categorize_uc() -> CategorizeTextUseCase:
    return CategorizeTextUseCase(_categorization_service())


def get_translations_uc() -> ListTranslationsUseCase:
    return ListTranslationsUseCase(_bible_provider())


def get_books_uc() -> ListBooksUseCase:
    return ListBooksUseCase(_bible_provider())


def get_chapter_uc() -> GetChapterUseCase:
    return GetChapterUseCase(_bible_provider())


def get_search_uc() -> SearchVersesUseCase:
    return SearchVersesUseCase(_bible_provider())


def current_user(authorization: str | None = Header(default=None)) -> dict:
    token = authorization.split(" ", 1)[1] if authorization and " " in authorization else authorization
    return _verifier().verify(token)
