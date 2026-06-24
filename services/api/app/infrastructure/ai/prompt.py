"""Shared prompt + strict output parsing for LLM providers.

Output is validated against the taxonomy; out-of-vocabulary tags are dropped.
"""
from __future__ import annotations

from app.domain.entities import Suggestion
from app.infrastructure.ai.taxonomy import TAXONOMY

_LABELS = ", ".join(lbl for lbl, _ in TAXONOMY.values())
_VALID = {slug: lbl for slug, (lbl, _) in TAXONOMY.items()}
_VALID_BY_LABEL = {lbl.lower(): slug for slug, lbl in _VALID.items()}


def build_system_prompt(max_suggestions: int) -> str:
    return (
        "You are a tagging assistant for a Christian journaling app. "
        f"Choose 1 to {max_suggestions} categories from EXACTLY this list: "
        f"[{_LABELS}]. "
        'Return strict JSON: {"suggestions":[{"slug","label","confidence"}]}. '
        "slug is the lowercase category. confidence is 0..1. "
        "Do not invent categories. Do not add commentary."
    )


def parse_suggestions(data: dict, max_suggestions: int) -> list[Suggestion]:
    raw = (data or {}).get("suggestions", [])
    out: list[Suggestion] = []
    seen: set[str] = set()
    for item in raw:
        slug = str(item.get("slug", "")).lower().strip()
        if slug not in _VALID:
            # try to recover from a label
            slug = _VALID_BY_LABEL.get(str(item.get("label", "")).lower().strip(), "")
        if not slug or slug in seen:
            continue
        seen.add(slug)
        try:
            conf = float(item.get("confidence", 0.7))
        except (TypeError, ValueError):
            conf = 0.7
        out.append(Suggestion(slug=slug, label=_VALID[slug], confidence=round(conf, 2)))
        if len(out) >= max_suggestions:
            break
    return out
