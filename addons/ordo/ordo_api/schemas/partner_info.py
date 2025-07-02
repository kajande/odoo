from pydantic import BaseModel
from typing import Optional


class PartnerInfo(BaseModel):
    name: str
    email: Optional[str]
