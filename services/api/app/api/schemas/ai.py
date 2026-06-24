from typing import Literal

from pydantic import BaseModel, Field


class CategorizeRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=2000)
    context: Literal["verse", "reflection", "prayer"] = "reflection"
    max_suggestions: int = Field(default=3, ge=1, le=5)
    locale: str = "en"


class SuggestionOut(BaseModel):
    slug: str
    label: str
    confidence: float


class CategorizeResponse(BaseModel):
    suggestions: list[SuggestionOut]
    provider: str
    fallback_used: bool


class CategoryOut(BaseModel):
    slug: str
    label: str


class CategoriesResponse(BaseModel):
    categories: list[CategoryOut]
