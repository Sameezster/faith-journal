"""Domain entities and value objects. Framework-agnostic."""
from __future__ import annotations

from dataclasses import dataclass, field


@dataclass(frozen=True)
class Suggestion:
    slug: str
    label: str
    confidence: float


@dataclass(frozen=True)
class Category:
    slug: str
    label: str
    synonyms: list[str] = field(default_factory=list)


@dataclass(frozen=True)
class Verse:
    number: int
    text: str


@dataclass(frozen=True)
class Chapter:
    translation: str
    book: str
    book_name: str
    chapter: int
    verses: list[Verse]

    @property
    def verse_count(self) -> int:
        return len(self.verses)


@dataclass(frozen=True)
class Book:
    osis_code: str
    name: str
    testament: str  # "OT" | "NT"
    order: int
    chapter_count: int
    # Sorted list of chapter numbers actually present in the data. Sample
    # translations may have only chapter 3 of John (etc.) — clients should
    # navigate to the first available chapter, not assume chapter 1 exists.
    chapter_numbers: tuple[int, ...] = ()


@dataclass(frozen=True)
class Translation:
    code: str
    name: str
    language: str
    license: str
    source: str


@dataclass(frozen=True)
class VerseHit:
    reference: str
    translation: str
    book: str
    chapter: int
    verse: int
    text: str
    rank: float
