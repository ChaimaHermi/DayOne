import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.midwife import Midwife, name_key


def get_by_id(db: Session, midwife_id: uuid.UUID) -> Midwife | None:
    return db.get(Midwife, midwife_id)


def get_by_name(db: Session, first_name: str, last_name: str) -> Midwife | None:
    return db.scalar(select(Midwife).where(Midwife.name_key == name_key(first_name, last_name)))


def create(db: Session, first_name: str, last_name: str, password_hash: str) -> Midwife:
    midwife = Midwife(
        first_name=first_name,
        last_name=last_name,
        name_key=name_key(first_name, last_name),
        password_hash=password_hash,
    )
    db.add(midwife)
    db.commit()
    db.refresh(midwife)
    return midwife
