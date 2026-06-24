# Faith Journal API (FastAPI service layer)

Owns **AI categorization** and **Bible content** only. All user data (verses,
reflections, prayers, reminders, profile) lives in Firebase/Firestore.

## Run locally (no keys needed — uses keyword fallback + bundled KJV/WEB)

    pip install fastapi "uvicorn[standard]" pydantic pydantic-settings \
        sqlalchemy alembic aiosqlite firebase-admin httpx pytest
    cp .env.example .env
    uvicorn app.main:app --reload --port 8080
    # open http://localhost:8080/docs

## Enable Gemini (MVP default)

Set `GEMINI_API_KEY` in `.env` and `pip install ".[ai]"`. The factory uses Gemini
first and automatically falls back to the keyword provider on error/timeout.

## Test

    pytest -q

## Clean Architecture layers
- `app/api`           — routers, Pydantic schemas, DI, error handlers
- `app/application`   — use-cases
- `app/domain`        — entities + ports (interfaces)
- `app/infrastructure`— adapters: ai (gemini/openai/keyword), bible (local bundled), firebase
