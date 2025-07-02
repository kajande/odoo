import logging

import aiohttp
import asyncio

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


WHATSAPP_ACCESS_TOKEN = "EAASKAWZBvUfMBO7A6qcpv9nE57y50TrZBQEs3ZBnR8zvacTVmxYNQAL3HkEhyUbz94f2XJWwZBGvxi55zlWfsDsTl2bkrrXQMdyaGKVGTRMq9EZBvkZBlKZCfAMDcQFg6FrCRXpIWqMILXjy39idPwwzHUH2r6M08SscZBmnbHDIm3gPWg2DxqqIT3N8ZBqvKqJnaPt0QERrKiN40DZBoQ"
WHATSAPP_PHONE_NUMBER_ID = "562403610286955"

async def send_message(to_number: str, message: str = '', media_urls: list[str] = [], media_type: str = 'image'):
    """
    Send a message to a WhatsApp number.
    """
    headers = {
        "Authorization": f"Bearer {WHATSAPP_ACCESS_TOKEN}",
        "Content-Type": "application/json"
    }
    
    url = f"https://graph.facebook.com/v22.0/{WHATSAPP_PHONE_NUMBER_ID}/messages"
    responses = []
    
    try:
        async with aiohttp.ClientSession() as session:
            if media_urls and media_type:
                for media_url in media_urls:
                    payload = {
                        "messaging_product": "whatsapp",
                        "recipient_type": "individual",
                        "to": to_number,
                        "type": media_type,
                        media_type: {
                            "link": media_url
                        }
                    }
                    if message:
                        payload[media_type]["caption"] = message
                    
                    async with session.post(url, headers=headers, json=payload) as response:
                        response.raise_for_status()
                        responses.append(await response.json())
                return responses
            else:
                payload = {
                    "messaging_product": "whatsapp",
                    "recipient_type": "individual",
                    "to": to_number,
                    "type": "text",
                    "text": {"body": message}
                }
                
                async with session.post(url, headers=headers, json=payload) as response:
                    response.raise_for_status()
                    return await response.json()
    except aiohttp.ClientError as e:
        logger.error(f"Failed to send message: {e}")
        return None
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        return None

async def report_error(error_message: str, sender_phone: str):
    return "Error from Whatsapp API"
