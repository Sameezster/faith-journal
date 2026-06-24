FROM python:3.12-slim AS base
ENV PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1
WORKDIR /app

COPY pyproject.toml ./
RUN pip install --upgrade pip && pip install fastapi "uvicorn[standard]" pydantic \
    pydantic-settings sqlalchemy alembic aiosqlite firebase-admin httpx

COPY app ./app
COPY data ./data
COPY alembic ./alembic
COPY scripts ./scripts

EXPOSE 8080
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
