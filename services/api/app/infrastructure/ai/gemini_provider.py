"""Google Gemini adapter (MVP default). Soft-imports the SDK so the service runs
without it installed; raises a typed error that the factory turns into a fallback.
"""
from __future__ import annotations

import json

from app.core.errors import AppError
from app.domain.entities import Suggestion
from app.infrastructure.ai.prompt import build_system_prompt, parse_suggestions


class GeminiProvider:
    name = "gemini"

    def __init__(self, api_key: str, model: str) -> None:
        self._api_key = api_key
        self._model_name = model

    async def suggest(self, text: str, context: str, max_suggestions: int) -> list[Suggestion]:
        try:
            import google.generativeai as genai  # type: ignore
        except ImportError as exc:  # pragma: no cover - optional dep
            raise AppError("ai_sdk_missing", "google-generativeai not installed", 503) from exc

        genai.configure(api_key=self._api_key)
        model = genai.GenerativeModel(
            self._model_name, system_instruction=build_system_prompt(max_suggestions)
        )
        resp = await model.generate_content_async(
            f"context={context}\ntext={text}",
            generation_config={"response_mime_type": "application/json", "temperature": 0.2},
        )
        data = json.loads(resp.text)
        return parse_suggestions(data, max_suggestions)
