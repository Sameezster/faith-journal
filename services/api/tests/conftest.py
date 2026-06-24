import os

os.environ.setdefault("AI_PROVIDER", "keyword")  # deterministic tests, no keys
os.environ.setdefault("AUTH_REQUIRED", "false")

import pytest
from fastapi.testclient import TestClient

from app.main import create_app


@pytest.fixture(scope="session")
def client() -> TestClient:
    return TestClient(create_app())
