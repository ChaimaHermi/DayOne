import uuid
from datetime import datetime

from sqlalchemy import DateTime, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


def name_key(first_name: str, last_name: str) -> str:
    """Clé d'unicité insensible à la casse et aux espaces."""
    first = " ".join(first_name.split()).casefold()
    last = " ".join(last_name.split()).casefold()
    return f"{first}|{last}"


class Midwife(Base):
    __tablename__ = "midwives"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    first_name: Mapped[str] = mapped_column(String(80))
    last_name: Mapped[str] = mapped_column(String(80))
    name_key: Mapped[str] = mapped_column(String(200), unique=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        default=lambda: datetime.now().astimezone(),
    )
