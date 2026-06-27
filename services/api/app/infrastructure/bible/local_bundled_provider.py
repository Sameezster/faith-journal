"""Local bundled Bible provider (KJV/WEB). License-clean, offline-friendly, fast."""
from __future__ import annotations

from app.core.errors import AppError
from app.domain.entities import Book, Chapter, Translation, Verse, VerseHit
from app.infrastructure.bible.loader import load_translations


class LocalBundledProvider:
    name = "local_bundled"

    def __init__(self, data_dir: str) -> None:
        self._data = load_translations(data_dir)

    def _translation_or_404(self, code: str) -> dict:
        t = self._data.get(code)
        if not t:
            raise AppError("translation_not_found", f"Translation '{code}' not available", 404)
        return t

    async def list_translations(self) -> list[Translation]:
        return [
            Translation(
                code=t["code"], name=t["name"], language=t.get("language", "en"),
                license=t.get("license", "public_domain"), source="bundled",
            )
            for t in self._data.values()
        ]

    async def list_books(self, translation: str) -> list[Book]:
        t = self._translation_or_404(translation)
        return [
            Book(
                osis_code=b["osis"], name=b["name"], testament=b["testament"],
                order=b["order"], chapter_count=len(b["chapters"]),
                chapter_numbers=tuple(sorted(int(c) for c in b["chapters"].keys())),
            )
            for b in t["books"]
        ]

    async def get_chapter(self, translation: str, book: str, chapter: int) -> Chapter:
        t = self._translation_or_404(translation)
        match = next((b for b in t["books"] if b["osis"].lower() == book.lower()), None)
        if not match:
            raise AppError("book_not_found", f"Book '{book}' not found", 404)
        verses_raw = match["chapters"].get(str(chapter))
        if not verses_raw:
            raise AppError("chapter_not_found", f"{book} {chapter} not available", 404)
        verses = [Verse(number=i + 1, text=txt) for i, txt in enumerate(verses_raw)]
        return Chapter(translation=translation, book=match["osis"],
                       book_name=match["name"], chapter=chapter, verses=verses)

    async def search(self, query: str, translation: str | None, limit: int) -> list[VerseHit]:
        q = query.lower().strip()
        hits: list[VerseHit] = []
        for code, t in self._data.items():
            if translation and code != translation:
                continue
            for b in t["books"]:
                for ch, verses in b["chapters"].items():
                    for idx, txt in enumerate(verses):
                        if q in txt.lower():
                            hits.append(VerseHit(
                                reference=f"{b['name']} {ch}:{idx + 1}", translation=code,
                                book=b["osis"], chapter=int(ch), verse=idx + 1, text=txt,
                                rank=round(txt.lower().count(q) / max(len(txt.split()), 1), 4),
                            ))
        hits.sort(key=lambda h: h.rank, reverse=True)
        return hits[:limit]
