from pydantic import BaseModel


class TranslationOut(BaseModel):
    code: str
    name: str
    language: str
    license: str
    source: str


class TranslationsResponse(BaseModel):
    translations: list[TranslationOut]


class BookOut(BaseModel):
    osis_code: str
    name: str
    order: int
    chapter_count: int


class BooksResponse(BaseModel):
    translation: str
    testaments: dict[str, list[BookOut]]


class VerseOut(BaseModel):
    number: int
    text: str


class ChapterResponse(BaseModel):
    translation: str
    book: str
    book_name: str
    chapter: int
    verse_count: int
    verses: list[VerseOut]


class VerseHitOut(BaseModel):
    reference: str
    translation: str
    book: str
    chapter: int
    verse: int
    text: str
    rank: float


class SearchResponse(BaseModel):
    query: str
    results: list[VerseHitOut]
    next_cursor: str | None = None
