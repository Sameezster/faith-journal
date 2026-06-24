from fastapi import APIRouter

from app.api.v1.routes import ai, bible, health

api_router = APIRouter()
api_router.include_router(health.router)
api_router.include_router(ai.router)
api_router.include_router(bible.router)
