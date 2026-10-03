# DayOne — Backend (FastAPI)

API REST du prototype DayOne. Pour l'instant, seule la route `GET /health` existe.

## Prérequis

- Python 3.11+
- PostgreSQL (pas nécessaire pour `/health`, prévu pour la suite)

## Installation

```powershell
cd backend
python -m venv venv
.\venv\Scripts\Activate.ps1        # Windows PowerShell
# source venv/bin/activate         # macOS / Linux
pip install -r requirements.txt
Copy-Item .env.example .env        # cp .env.example .env sous macOS / Linux
```

## Lancement

```powershell
uvicorn app.main:app --reload
```

Pour qu'un téléphone Android physique (ou l'émulateur) puisse joindre l'API, écouter sur toutes les interfaces :

```powershell
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- Health check : http://localhost:8000/health → `{"status": "ok"}`
- Documentation interactive : http://localhost:8000/docs

## Tests

```powershell
pytest
```

## Structure

```
app/
├── main.py          # Création de l'app FastAPI, CORS, routers
├── api/             # Routes HTTP (router.py + routes/)
├── core/            # Configuration (config.py) et base de données (database.py)
├── models/          # Modèles SQLAlchemy (vide pour l'instant)
├── schemas/         # Schémas Pydantic (entrée / sortie API)
├── services/        # Logique métier (vide pour l'instant)
└── repositories/    # Accès aux données (vide pour l'instant)
tests/               # Tests pytest
```

## Configuration (`.env`)

| Variable       | Description                                   |
|----------------|-----------------------------------------------|
| `APP_NAME`     | Nom affiché dans la doc OpenAPI               |
| `ENVIRONMENT`  | `development` / `production`                  |
| `DATABASE_URL` | URL SQLAlchemy PostgreSQL (driver `psycopg`)  |
| `CORS_ORIGINS` | Origines autorisées, séparées par des virgules |
