"""Loads bundled public-domain Bible JSON from disk into memory.

JSON schema (per translation file, e.g. KJV.sample.json):
{
  "code": "KJV", "name": "King James Version", "language": "en",
  "license": "public_domain",
  "books": [
    {"osis": "John", "name": "John", "testament": "NT", "order": 43,
     "chapters": {"3": ["v1 text", "v16 text", ...]}}
  ]
}

In production scripts/seed_bible.py loads full KJV/WEB into Postgres; this in-memory
loader keeps the MVP runnable and powers the LocalBundledProvider.
"""
from __future__ import annotations

import json
from functools import lru_cache
from pathlib import Path


@lru_cache
def load_translations(data_dir: str) -> dict[str, dict]:
    base = Path(data_dir)
    out: dict[str, dict] = {}
    for fp in sorted(base.glob("*.json")):
        with fp.open(encoding="utf-8") as fh:
            data = json.load(fh)
        out[data["code"]] = data
    return out
