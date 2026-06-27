"""Build a full KJV.json file for the bundled Bible provider.

Pulls each of the 66 books from the public-domain `aruljohn/Bible-kjv`
GitHub mirror, transforms to the schema expected by `local_bundled_provider`
(`books[].chapters["1"] = [verse_text, ...]`), and writes
`services/api/data/bibles/KJV.json`. The original sample file
`KJV.sample.json` is removed afterward so the loader doesn't double-register
the same translation code.

Usage:
    python -m scripts.build_kjv
"""
from __future__ import annotations

import json
import sys
import time
from pathlib import Path

import httpx

from .bible_books import BOOKS

BASE_URL = "https://raw.githubusercontent.com/aruljohn/Bible-kjv/master"


def source_filename(display_name: str) -> str:
    """aruljohn's filenames are the display name with spaces stripped:
    'Genesis' -> 'Genesis', '1 Samuel' -> '1Samuel', 'Song of Solomon' -> 'SongofSolomon'."""
    return display_name.replace(" ", "")


def fetch(client: httpx.Client, filename: str, retries: int = 6) -> dict:
    """Fetch one book file with exponential backoff. GitHub's raw CDN
    occasionally returns 400/429/5xx under burst load — we retry."""
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


def transform(raw: dict, osis: str, name: str, testament: str, order: int) -> dict:
    """Convert aruljohn's per-book JSON to local_bundled_provider's schema."""
    chapters: dict[str, list[str]] = {}
    for ch in raw["chapters"]:
        # Source uses string chapter numbers; keep as strings for our schema.
        chapter_key = str(ch["chapter"])
        chapters[chapter_key] = [v["text"] for v in ch["verses"]]
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
    out_path = data_dir / "KJV.json"

    print(f"Downloading 66 books from {BASE_URL}")
    out_books: list[dict] = []
    total_chapters = 0
    total_verses = 0
    headers = {"User-Agent": "faith-journal-build-kjv/1.0"}
    with httpx.Client(follow_redirects=True, headers=headers) as client:
        for osis, name, testament, order in BOOKS:
            filename = source_filename(name)
            print(f"  {order:2}/66  {name}", flush=True)
            raw = fetch(client, filename)
            book = transform(raw, osis, name, testament, order)
            out_books.append(book)
            total_chapters += len(book["chapters"])
            total_verses += sum(len(v) for v in book["chapters"].values())
            # Polite pause so we don't burst-hit the raw CDN.
            time.sleep(0.3)

    out = {
        "code": "KJV",
        "name": "King James Version",
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

    sample = data_dir / "KJV.sample.json"
    if sample.exists():
        sample.unlink()
        print(f"Removed {sample.relative_to(here.parent.parent)} (replaced by full KJV)")

    return 0


if __name__ == "__main__":
    sys.exit(main())
