from typing import Annotated
from fastapi import APIRouter, Depends
from pydantic import BaseModel

from odoo.api import Environment
from odoo.addons.fastapi.dependencies import odoo_env

from odoo.addons.ordo_api.schemas import PartnerInfo

router = APIRouter()

@router.get("/partners", response_model=list[PartnerInfo])
def get_partners(env: Annotated[Environment, Depends(odoo_env)]) -> list[PartnerInfo]:
    return [
        PartnerInfo(
            name=partner.name,
            email=partner.email or None
        )
        for partner in env["res.partner"].search([])
    ]
