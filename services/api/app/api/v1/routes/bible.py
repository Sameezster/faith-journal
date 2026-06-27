from fastapi import APIRouter, Depends, Query

from app.api.deps import (
    current_user, get_books_uc, get_chapter_uc, get_search_uc, get_translations_uc,
)
from app.api.schemas.bible import (
    BooksResponse, ChapterResponse, SearchResponse, TranslationsResponse,
)
from app.application.usecases.bible_usecases import (
    GetChapterUseCase, ListBooksUseCase, ListTranslationsUseCase, SearchVersesUseCase,
)

router = APIRouter(prefix="/bible", tags=["bible"])


@router.get("/translations", response_model=TranslationsResponse)
async def translations(
    uc: ListTranslationsUseCase = Depends(get_translations_uc), _u: dict = Depends(current_user)
) -> TranslationsResponse:
    items = await uc.execute()
    return TranslationsResponse(translations=[t.__dict__ for t in items])


@router.get("/{translation}/books", response_model=BooksResponse)
async def books(
    translation: str, uc: ListBooksUseCase = Depends(get_books_uc), _u: dict = Depends(current_user)
) -> BooksResponse:
    items = await uc.execute(translation)
    grouped: dict[str, list] = {"OT": [], "NT": []}
    for b in sorted(items, key=lambda x: x.order):
        grouped.setdefault(b.testament, []).append({
            "osis_code": b.osis_code, "name": b.name, "order": b.order,
            "chapter_count": b.chapter_count,
            "chapter_numbers": list(b.chapter_numbers),
        })
    return BooksResponse(translation=translation, testaments=grouped)


@router.get("/search", response_model=SearchResponse)
async def search(
    q: str = Query(..., min_length=2),
    translation: str | None = None,
    limit: int = Query(20, ge=1, le=100),
    uc: SearchVersesUseCase = Depends(get_search_uc),
    _u: dict = Depends(current_user),
) -> SearchResponse:
    hits = await uc.execute(q, translation, limit)
    return SearchResponse(query=q, results=[h.__dict__ for h in hits])


@router.get("/{translation}/{book}/{chapter}", response_model=ChapterResponse)
async def chapter(
    translation: str, book: str, chapter: int,
    uc: GetChapterUseCase = Depends(get_chapter_uc), _u: dict = Depends(current_user),
) -> ChapterResponse:
    ch = await uc.execute(translation, book, chapter)
    return ChapterResponse(
        translation=ch.translation, book=ch.book, book_name=ch.book_name,
        chapter=ch.chapter, verse_count=ch.verse_count,
        verses=[{"number": v.number, "text": v.text} for v in ch.verses],
    )
