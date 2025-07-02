from fastapi import APIRouter

from .partners import router as partners_router

ordo_api_router = APIRouter()


ordo_api_router.include_router(partners_router)
