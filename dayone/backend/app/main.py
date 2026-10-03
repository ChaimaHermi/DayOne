from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.router import api_router
from app.core.config import get_settings

settings = get_settings()

app = FastAPI(title=settings.app_name)

origins = settings.cors_origins_list
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    # Browsers reject credentials with a wildcard origin.
    allow_credentials="*" not in origins,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router)
