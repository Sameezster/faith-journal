# Migrations (Bible content + AI taxonomy/telemetry only)

User data lives in Firestore and is **not** modeled here. These migrations cover
`translations`, `books`, `chapters`, `verses` (with a GIN tsvector index), and the
`categories` / `categorization_logs` tables described in the architecture doc §10.

    alembic revision -m "baseline bible schema"
    alembic upgrade head
    python -m scripts.seed_bible
