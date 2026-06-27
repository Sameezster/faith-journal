"""Build a full WEB.json file for the bundled Bible provider.

Pulls each of the 66 books from `TehShrike/world-english-bible`, which exposes
WEB as a per-book JSON file of paragraph items. We filter to the
`paragraph text` items, group them by (chapter, verse), concatenate any
multi-paragraph verses, and emit the same `books[].chapters["1"] = [verse_text, ...]`
shape that `local_bundled_provider` already consumes.

Usage:
    python -m scripts.build_web
"""
from __future__ import annotations

import json
import re
import sys
import time
from collections import defaultdict
from pathlib import Path

import httpx

from .bible_books import BOOKS

BASE_URL = "https://raw.githubusercontent.com/TehShrike/world-english-bible/master/json"


def source_filename(display_name: str) -> str:
    """Map a display name like '1 Samuel' or 'Song of Solomon' to the
    TehShrike filename stem (lowercase, no spaces)."""
    return re.sub(r"\s+", "", display_name).lower()


def fetch(client: httpx.Client, filename: str, retries: int = 6) -> list[dict]:
    url = f"{BASE_URL}/{filename}.json"
    last_err: Exception | None = None
    for attempt in range(1, retries + 1):
        try:
            res = client.get(url, timeout=30.0)
            res.raise_for_status()
            return res.json()
        except (httpx.HTTPError, httpx.TimeoutException) as e:
            last_err = e
            if attempt < retries:
                sleep_s = min(2 ** attempt, 30)
                print(
                    f"      retry {attempt}/{retries} after {sleep_s}s ({e})",
                    flush=True,
                )
                time.sleep(sleep_s)
    raise RuntimeError(f"Failed to fetch {url}: {last_err}")


_TEXT_TYPES = frozenset({"paragraph text", "line text"})


def transform(items: list[dict], osis: str, name: str, testament: str, order: int) -> dict:
    """Walk the source items, collecting verse text by (chapter, verse).

    Prose books use `paragraph text`; poetic books (Psalms, Proverbs, Song of
    Solomon, Lamentations, parts of the Prophets) use `line text`. A verse can
    be split across multiple text items — we join with a single space.
    """
    by_verse: dict[tuple[int, int], list[str]] = defaultdict(list)
    for item in items:
        if item.get("type") not in _TEXT_TYPES:
            continue
        ch = item.get("chapterNumber")
        v = item.get("verseNumber")
        text = (item.get("value") or "").strip()
        if ch is None or v is None or not text:
            continue
        by_verse[(int(ch), int(v))].append(text)

    chapters: dict[str, list[str]] = {}
    if not by_verse:
        return {
            "osis": osis,
            "name": name,
            "testament": testament,
            "order": order,
            "chapters": chapters,
        }

    max_ch = max(ch for (ch, _) in by_verse)
    for ch in range(1, max_ch + 1):
        verses = [(v, ' '.join(by_verse[(ch, v)]))
                  for (c, v) in by_verse if c == ch]
        verses.sort(key=lambda kv: kv[0])
        if verses:
            chapters[str(ch)] = [text for _, text in verses]

    return {
        "osis": osis,
        "name": name,
        "testament": testament,
        "order": order,
        "chapters": chapters,
    }


def main() -> int:
    here = Path(__file__).resolve().parent.parent  # services/api
    data_dir = here / "data" / "bibles"
    data_dir.mkdir(parents=True, exist_ok=True)
    out_path = data_dir / "WEB.json"

    print(f"Downloading 66 books from {BASE_URL}")
    out_books: list[dict] = []
    total_chapters = 0
    total_verses = 0
    headers = {"User-Agent": "faith-journal-build-web/1.0"}
    with httpx.Client(follow_redirects=True, headers=headers) as client:
        for osis, name, testament, order in BOOKS:
            filename = source_filename(name)
            print(f"  {order:2}/66  {name}  ({filename}.json)", flush=True)
            items = fetch(client, filename)
            book = transform(items, osis, name, testament, order)
            if not book["chapters"]:
                raise RuntimeError(
                    f"{name} returned 0 chapters — source format may have changed"
                )
            out_books.append(book)
            total_chapters += len(book["chapters"])
            total_verses += sum(len(v) for v in book["chapters"].values())
            time.sleep(0.3)  # be polite to the CDN

    out = {
        "code": "WEB",
        "name": "World English Bible",
        "language": "en",
        "license": "public_domain",
        "books": out_books,
    }
    out_path.write_text(json.dumps(out, ensure_ascii=False), encoding="utf-8")
    print(
        f"\nWrote {out_path.relative_to(here.parent.parent)}  "
        f"({total_chapters} chapters, {total_verses} verses, "
        f"{out_path.stat().st_size // 1024} KB)"
    )

    sample = data_dir / "WEB.sample.json"
    if sample.exists():
        sample.unlink()
        print(f"Removed {sample.relative_to(here.parent.parent)} (replaced by full WEB)")

    return 0


if __name__ == "__main__":
    sys.exit(main())
