from fastapi import APIRouter

from .whatsapp import router as whatsapp_router

ordo_webhook_router = APIRouter()


ordo_webhook_router.include_router(whatsapp_router)
