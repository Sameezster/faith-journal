"""Deterministic keyword/rule-based categorization. Always available; never fails.

This is the guaranteed fallback so /ai/categorize returns usable suggestions even
with zero AI keys configured.
"""
from __future__ import annotations

import re

from app.domain.entities import Suggestion
from app.infrastructure.ai.taxonomy import FAMILY_KEYWORDS, TAXONOMY

_WORD_RE = re.compile(r"[a-z]+")

# "Family" is not part of the core spiritual taxonomy but is a useful prayer category
# (per the brief's "pray for my mother's health" -> Healing, Family, Faith example).
_EXTRA = {"family": ("Family", FAMILY_KEYWORDS)}


class KeywordRuleProvider:
    name = "keyword"

    async def suggest(self, text: str, context: str, max_suggestions: int) -> list[Suggestion]:
        tokens = _WORD_RE.findall((text or "").lower())
        if not tokens:
            return []
        token_set = set(tokens)
        scores: dict[str, tuple[str, float]] = {}

        def add(slug: str, label: str, kws: list[str]) -> None:
            hits = sum(1 for kw in kws if kw in token_set)
            if hits:
                scores[slug] = (label, float(hits))

        for slug, (label, kws) in TAXONOMY.items():
            add(slug, label, kws)
        # Family only relevant for prayer/reflection contexts
        if context in ("prayer", "reflection"):
            for slug, (label, kws) in _EXTRA.items():
                add(slug, label, kws)

        if not scores:
            return []

        max_hits = max(v[1] for v in scores.values())
        ranked = sorted(scores.items(), key=lambda kv: kv[1][1], reverse=True)
        out: list[Suggestion] = []
        for slug, (label, hits) in ranked[:max_suggestions]:
            confidence = round(0.5 + 0.5 * (hits / max_hits), 2)  # 0.5..1.0
            out.append(Suggestion(slug=slug, label=label, confidence=confidence))
        return out
