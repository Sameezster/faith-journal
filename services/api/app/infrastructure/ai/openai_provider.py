"""OpenAI adapter (optional, addable later without code changes elsewhere)."""
from __future__ import annotations

import json

from app.core.errors import AppError
from app.domain.entities import Suggestion
from app.infrastructure.ai.prompt import build_system_prompt, parse_suggestions


class OpenAIProvider:
    name = "openai"

    def __init__(self, api_key: str, model: str) -> None:
        self._api_key = api_key
        self._model_name = model

    async def suggest(self, text: str, context: str, max_suggestions: int) -> list[Suggestion]:
        try:
            from openai import AsyncOpenAI  # type: ignore
        except ImportError as exc:  # pragma: no cover - optional dep
            raise AppError("ai_sdk_missing", "openai not installed", 503) from exc

        client = AsyncOpenAI(api_key=self._api_key)
        resp = await client.chat.completions.create(
            model=self._model_name,
            temperature=0.2,
            response_format={"type": "json_object"},
            messages=[
                {"role": "system", "content": build_system_prompt(max_suggestions)},
                {"role": "user", "content": f"context={context}\ntext={text}"},
            ],
        )
        data = json.loads(resp.choices[0].message.content or "{}")
        return parse_suggestions(data, max_suggestions)
