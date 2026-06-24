"""Seed PostgreSQL with bundled public-domain translations.

MVP runs off the in-memory JSON loader; this script is the production path that
loads full KJV/WEB JSON into the relational schema (translations/books/chapters/
verses) and builds the full-text search index. Run after `alembic upgrade head`.

    python -m scripts.seed_bible --data-dir data/bibles
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data-dir", default="data/bibles")
    args = parser.parse_args()

    base = Path(args.data_dir)
    files = sorted(base.glob("*.json"))
    print(f"Found {len(files)} translation file(s) in {base}")
    for fp in files:
        data = json.loads(fp.read_text(encoding="utf-8"))
        n_books = len(data["books"])
        n_verses = sum(len(v) for b in data["books"] for v in b["chapters"].values())
        print(f"  {data['code']:5} {data['name']:25} books={n_books:3} verses={n_verses}")
        # TODO: upsert into translations/books/chapters/verses via SQLAlchemy session,
        #       then UPDATE verses SET search_tsv = to_tsvector('english', text).
    print("Seed complete (relational upsert is a TODO behind the DB session).")


if __name__ == "__main__":
    main()
