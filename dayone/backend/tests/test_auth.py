import uuid

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.database import Base, get_db
from app.main import app
from app.models import midwife as _midwife  # noqa: F401

engine = create_engine(
    "sqlite://",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSession = sessionmaker(bind=engine, autoflush=False, autocommit=False)


@pytest.fixture()
def client():
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)

    def override_db():
        db = TestingSession()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


def test_register_then_me(client: TestClient):
    response = client.post(
        "/auth/register",
        json={"first_name": "Aïcha", "last_name": "Ndiaye", "password": "registre2026"},
    )
    assert response.status_code == 201
    body = response.json()
    assert body["midwife"]["first_name"] == "Aïcha"
    assert body["midwife"]["last_name"] == "Ndiaye"
    assert "password" not in body["midwife"]
    uuid.UUID(body["midwife"]["id"])

    me = client.get("/auth/me", headers={"Authorization": f"Bearer {body['access_token']}"})
    assert me.status_code == 200
    assert me.json()["first_name"] == "Aïcha"


def test_register_rejects_duplicate_name_ignoring_case(client: TestClient):
    payload = {"first_name": "Amina", "last_name": "Diallo", "password": "registre2026"}
    assert client.post("/auth/register", json=payload).status_code == 201
    again = client.post(
        "/auth/register",
        json={"first_name": " amina ", "last_name": "DIALLO", "password": "autreMotDePasse"},
    )
    assert again.status_code == 409


def test_login_and_wrong_password(client: TestClient):
    client.post(
        "/auth/register",
        json={"first_name": "Fatou", "last_name": "Sow", "password": "registre2026"},
    )
    ok = client.post(
        "/auth/login",
        json={"first_name": "fatou", "last_name": "sow", "password": "registre2026"},
    )
    assert ok.status_code == 200
    assert ok.json()["access_token"]

    bad = client.post(
        "/auth/login",
        json={"first_name": "Fatou", "last_name": "Sow", "password": "mauvais"},
    )
    assert bad.status_code == 401

    unknown = client.post(
        "/auth/login",
        json={"first_name": "Inconnue", "last_name": "Personne", "password": "registre2026"},
    )
    assert unknown.status_code == 401
    assert bad.json()["detail"] == unknown.json()["detail"]


def test_me_requires_token(client: TestClient):
    assert client.get("/auth/me").status_code == 401
    assert client.get("/auth/me", headers={"Authorization": "Bearer pas-un-jeton"}).status_code == 401


def test_register_rejects_short_password(client: TestClient):
    response = client.post(
        "/auth/register",
        json={"first_name": "Awa", "last_name": "Ba", "password": "court"},
    )
    assert response.status_code == 422
