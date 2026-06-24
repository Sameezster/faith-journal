"""The fixed 11-category taxonomy plus weighted synonyms for the keyword fallback.

Also encodes a few "intent" mappings (e.g. worry/fear -> faith, hope, peace) so the
deterministic fallback matches the product examples in the brief.
"""
from __future__ import annotations

from app.domain.entities import Category

# slug -> (label, synonyms/keywords used by the keyword fallback)
TAXONOMY: dict[str, tuple[str, list[str]]] = {
    "strength": ("Strength", ["strength", "strong", "strengthen", "power", "endure", "courage"]),
    "faith": ("Faith", ["faith", "believe", "trust", "future", "worried", "worry", "doubt"]),
    "hope": ("Hope", ["hope", "future", "promise", "expect", "tomorrow", "wait"]),
    "wisdom": ("Wisdom", ["wisdom", "wise", "understanding", "guidance", "discern", "knowledge"]),
    "prayer": ("Prayer", ["pray", "prayer", "intercede", "petition", "ask"]),
    "love": ("Love", ["love", "loving", "compassion", "kindness", "charity"]),
    "forgiveness": ("Forgiveness", ["forgive", "forgiveness", "mercy", "pardon", "grace"]),
    "healing": ("Healing", ["heal", "healing", "health", "sick", "sickness", "recovery", "pain", "disease"]),
    "peace": ("Peace", ["peace", "calm", "rest", "anxiety", "anxious", "afraid", "fear", "worried", "worry"]),
    "gratitude": ("Gratitude", ["thank", "thankful", "grateful", "gratitude", "praise", "blessing"]),
    "encouragement": ("Encouragement", ["encourage", "encouragement", "uplift", "comfort", "strengthened"]),
}

# Extra context keywords that imply a category not obvious from the word itself.
FAMILY_KEYWORDS = ["mother", "father", "family", "son", "daughter", "wife", "husband", "child", "parent"]


def categories() -> list[Category]:
    return [Category(slug=s, label=lbl, synonyms=syn) for s, (lbl, syn) in TAXONOMY.items()]


def label_for(slug: str) -> str:
    return TAXONOMY[slug][0]
