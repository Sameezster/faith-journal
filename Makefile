.PHONY: api.venv api.dev api.test api.seed app.setup app.run app.test firebase.deploy

API_VENV := services/api/.venv
API_PY   := $(API_VENV)/bin/python
API_PIP  := $(API_VENV)/bin/pip

# One-time venv bootstrap. Uses python3.13 if available, else python3.
$(API_PY):
	@python3.13 -m venv $(API_VENV) 2>/dev/null || python3 -m venv $(API_VENV)
	$(API_PIP) install --upgrade pip
	$(API_PIP) install fastapi 'uvicorn[standard]' pydantic pydantic-settings sqlalchemy alembic aiosqlite firebase-admin httpx pytest pytest-asyncio

api.venv: $(API_PY)

api.dev: $(API_PY)
	cd services/api && ../../$(API_VENV)/bin/uvicorn app.main:app --reload --host 0.0.0.0 --port 8080

api.test: $(API_PY)
	cd services/api && AI_PROVIDER=keyword AUTH_REQUIRED=false ../../$(API_PY) -m pytest -q

api.seed: $(API_PY)
	cd services/api && ../../$(API_PY) -m scripts.seed_bible --data-dir data/bibles

# Download full public-domain KJV and overwrite data/bibles/KJV.json.
# Run once on initial setup, or whenever you want to refresh from upstream.
api.bible.kjv: $(API_PY)
	cd services/api && ../../$(API_PY) -m scripts.build_kjv

# Download full public-domain WEB (World English Bible) -> data/bibles/WEB.json.
api.bible.web: $(API_PY)
	cd services/api && ../../$(API_PY) -m scripts.build_web

# Build all bundled translations.
api.bible.all: api.bible.kjv api.bible.web

app.setup:
	cd apps/mobile && flutter pub get && dart run build_runner build --delete-conflicting-outputs

app.run:
	cd apps/mobile && flutter run

app.test:
	cd apps/mobile && flutter test

firebase.deploy:
	cd firebase && firebase deploy --only firestore:rules,firestore:indexes,storage,functions
