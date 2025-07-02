from typing import Annotated, Optional
from fastapi import FastAPI, APIRouter, Depends
from fastapi.middleware.cors import CORSMiddleware
from uvicorn.middleware.proxy_headers import ProxyHeadersMiddleware

from pydantic import BaseModel

from odoo import fields, models
from odoo.api import Environment
from odoo.addons.fastapi.dependencies import odoo_env

from odoo.addons.ordo_api.routers import ordo_api_router
from odoo.addons.ordo_api.webhooks import ordo_webhook_router


class FastapiEndpoint(models.Model):
    _inherit = "fastapi.endpoint"

    app = fields.Selection(
        selection_add=[
            ("demo", "Demo Endpoint"),
            ("ordo", "Ordo Endpoint"),
        ],
        ondelete={
            "demo": "cascade",
            "ordo": "cascade",
        },
    )

    def _get_app(self) -> FastAPI:
        app = super()._get_app()
        if self.app == "demo":
            # Add CORS middleware
            app.add_middleware(
                CORSMiddleware,
                allow_origins=["*"],
                allow_credentials=True,
                allow_methods=["*"],
                allow_headers=["*"],
            )
            
            # Add ProxyHeaders middleware
            app.add_middleware(ProxyHeadersMiddleware, trusted_hosts=["*"])
        return app

    def _get_fastapi_routers(self):
        if self.app == "demo":
            return [demo_api_router]
        if self.app == "ordo":
            return [ordo_api_router, ordo_webhook_router]
        return super()._get_fastapi_routers()

demo_api_router = APIRouter()

class PartnerInfo(BaseModel):
    name: str
    email: Optional[str]

@demo_api_router.get("/partners", response_model=list[PartnerInfo])
def get_partners(env: Annotated[Environment, Depends(odoo_env)]) -> list[PartnerInfo]:
    return [
        PartnerInfo(
            name=partner.name,
            email=partner.email or None
        )
        for partner in env["res.partner"].search([])
    ]
