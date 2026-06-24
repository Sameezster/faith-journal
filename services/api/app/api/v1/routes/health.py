from fastapi import APIRouter

from app.core.config import get_settings

router = APIRouter(tags=["health"])


@router.get("/health")
async def health() -> dict:
    s = get_settings()
    return {"status": "ok", "environment": s.environment, "ai_provider": s.ai_provider}
