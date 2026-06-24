"""Verifies Firebase ID tokens via the Admin SDK.

In dev (auth_required=False) the verifier is relaxed so the API runs without a
service account; staging/prod set auth_required=True and provide credentials.
"""
from __future__ import annotations

import logging

from app.core.config import Settings
from app.core.errors import AppError

log = logging.getLogger(__name__)


class FirebaseTokenVerifier:
    def __init__(self, settings: Settings) -> None:
        self._settings = settings
        self._app = None
        if settings.google_application_credentials:
            try:  # pragma: no cover - requires real credentials
                import firebase_admin
                from firebase_admin import credentials

                cred = credentials.Certificate(settings.google_application_credentials)
                self._app = firebase_admin.initialize_app(cred)
            except Exception as exc:  # noqa: BLE001
                log.warning("Firebase Admin init failed: %s", exc)

    def verify(self, token: str | None) -> dict:
        if not self._settings.auth_required:
            return {"uid": "dev-user", "dev_mode": True}
        if not token:
            raise AppError("unauthorized", "Missing bearer token", 401)
        try:  # pragma: no cover - requires real credentials
            from firebase_admin import auth

            return auth.verify_id_token(token)
        except Exception as exc:  # noqa: BLE001
            raise AppError("unauthorized", "Invalid token", 401) from exc
