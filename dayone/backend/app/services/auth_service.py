import uuid
from datetime import datetime, timedelta, timezone

import bcrypt
import jwt
from fastapi import HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models.midwife import Midwife
from app.repositories import midwife_repository as repo
from app.schemas.auth import AuthResponse, LoginRequest, MidwifePublic, RegisterRequest

_INVALID_LOGIN = "Prénom, nom ou mot de passe incorrect."


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(password: str, password_hash: str) -> bool:
    return bcrypt.checkpw(password.encode("utf-8"), password_hash.encode("utf-8"))


def create_access_token(midwife_id: uuid.UUID) -> str:
    settings = get_settings()
    expires = datetime.now(timezone.utc) + timedelta(days=settings.jwt_expire_days)
    return jwt.encode(
        {"sub": str(midwife_id), "exp": expires},
        settings.jwt_secret,
        algorithm="HS256",
    )


def _response(midwife: Midwife) -> AuthResponse:
    return AuthResponse(access_token=create_access_token(midwife.id), midwife=MidwifePublic.model_validate(midwife))


def register(db: Session, payload: RegisterRequest) -> AuthResponse:
    if repo.get_by_name(db, payload.first_name, payload.last_name) is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Un compte existe déjà pour ce prénom et ce nom.",
        )
    try:
        midwife = repo.create(db, payload.first_name, payload.last_name, hash_password(payload.password))
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Un compte existe déjà pour ce prénom et ce nom.",
        ) from None
    return _response(midwife)


def login(db: Session, payload: LoginRequest) -> AuthResponse:
    midwife = repo.get_by_name(db, payload.first_name, payload.last_name)
    if midwife is None or not verify_password(payload.password, midwife.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=_INVALID_LOGIN)
    return _response(midwife)


def midwife_from_token(db: Session, token: str) -> Midwife:
    settings = get_settings()
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=["HS256"])
        midwife_id = uuid.UUID(str(payload["sub"]))
    except (jwt.PyJWTError, ValueError, TypeError):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Session invalide.") from None
    midwife = repo.get_by_id(db, midwife_id)
    if midwife is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Session invalide.")
    return midwife
