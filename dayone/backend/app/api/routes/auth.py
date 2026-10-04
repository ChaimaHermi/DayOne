from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_midwife
from app.core.database import get_db
from app.models.midwife import Midwife
from app.schemas.auth import AuthResponse, LoginRequest, MidwifePublic, RegisterRequest
from app.services import auth_service

# Compte sage-femme : inscription, connexion, session.
router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=AuthResponse, status_code=201)
def register(payload: RegisterRequest, db: Annotated[Session, Depends(get_db)]) -> AuthResponse:
    return auth_service.register(db, payload)


@router.post("/login", response_model=AuthResponse)
def login(payload: LoginRequest, db: Annotated[Session, Depends(get_db)]) -> AuthResponse:
    return auth_service.login(db, payload)


@router.get("/me", response_model=MidwifePublic)
def me(midwife: Annotated[Midwife, Depends(get_current_midwife)]) -> Midwife:
    return midwife
