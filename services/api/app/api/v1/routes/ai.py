from fastapi import APIRouter, Depends

from app.api.deps import current_user, get_categorize_uc
from app.api.schemas.ai import (
    CategoriesResponse, CategorizeRequest, CategorizeResponse,
)
from app.application.usecases.categorize_text import CategorizeTextUseCase
from app.infrastructure.ai.taxonomy import categories as taxonomy_categories

router = APIRouter(prefix="/ai", tags=["ai"])


@router.post("/categorize", response_model=CategorizeResponse)
async def categorize(
    payload: CategorizeRequest,
    uc: CategorizeTextUseCase = Depends(get_categorize_uc),
    _user: dict = Depends(current_user),
) -> CategorizeResponse:
    result = await uc.execute(payload.text, payload.context, payload.max_suggestions)
    return CategorizeResponse(
        suggestions=[s.__dict__ for s in result.suggestions],
        provider=result.provider,
        fallback_used=result.fallback_used,
    )


@router.get("/categories", response_model=CategoriesResponse)
async def categories(_user: dict = Depends(current_user)) -> CategoriesResponse:
    return CategoriesResponse(
        categories=[{"slug": c.slug, "label": c.label} for c in taxonomy_categories()]
    )
