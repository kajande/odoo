global processed

processed = False


async def is_message_processed(message_id: str) -> bool:
    return processed
    # result = supabase.table("processed_messages") \
    #     .select("message_id") \
    #     .eq("message_id", message_id) \
    #     .execute()
    # return len(result.data) > 0

async def mark_message_processed(message_id: str, sender_phone: str):
    processed = True
