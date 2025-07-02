from fastapi import APIRouter, Depends, Request, HTTPException
from fastapi.responses import PlainTextResponse
from odoo.api import Environment
from odoo.addons.fastapi.dependencies import odoo_env
from typing import Annotated

from . import controller, account, meta

import logging

# Create and configure logger
logging.basicConfig(level=logging.DEBUG)
_logger = logging.getLogger(__name__)
if not _logger.hasHandlers():
    handler = logging.StreamHandler()
    formatter = logging.Formatter('%(asctime)s %(levelname)s %(name)s: %(message)s')
    handler.setFormatter(formatter)
    _logger.addHandler(handler)
    _logger.setLevel(logging.DEBUG)



WHATSAPP_VERIFY_TOKEN = "kajande"

router = APIRouter()

@router.get("/debug-log")
async def debug_log_test():
    _logger.info("✅ Logger is working")
    return {"message": "Logged!"}


@router.get("/whatsapp")
async def verify_webhook(request: Request):
    # Webhook verification
    mode = request.query_params.get("hub.mode")
    token = request.query_params.get("hub.verify_token")
    challenge = request.query_params.get("hub.challenge")
    
    if mode == "subscribe" and token == WHATSAPP_VERIFY_TOKEN:
        return PlainTextResponse(content=challenge)
    raise HTTPException(status_code=403, detail="Verification failed")

@router.post("/whatsapp")
async def handle_message(
    request: Request,
    env: Annotated[Environment, Depends(odoo_env)]
):
    try:
        data = await request.json()
        _logger.info(f"\n\nReceived WhatsApp message: {data}\n\n")
        # Add your message processing logic here

        data = await request.json()
        for entry in data.get("entry", []):
            for change in entry.get("changes", []):
                if change.get("field") == "messages":
                    value = change.get("value", {})
                    messages = value.get("messages", [])
                    for message in messages:
                        message_id = message.get("id")
                        from_number = message.get("from")
                        
                        # Check Supabase
                        if await account.is_message_processed(message_id):
                            continue
                        
                        await account.mark_message_processed(message_id, from_number)
                        
                        # Process message
                        message_type = message.get("type")
                        try:
                            await controller.welcome_user(from_number)
                            if message_type == "text":
                                text_body = message.get("text", {}).get("body", "")
                                await controller.handle_simple_message(text_body, from_number)
                            elif message_type in ["image", "document", "audio", "video"]:
                                media_info = message.get(message_type, {})
                                media_id = media_info.get("id")
                                caption = media_info.get("caption", "")
                                await controller.handle_media_message(caption, from_number, media_id, message_type)
                        except Exception as e:
                            await meta.report_error(str(e), from_number)
        
        return {"status": "ok"}
    except Exception as e:
        return {"status": "error", "details": str(e)}
