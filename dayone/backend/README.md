# DayOne — Backend

Le guide d’installation complet (PostgreSQL, `.env`, Alembic, lancement) est dans le [README à la racine du dépôt](../../README.md).

Depuis ce dossier, avec le venv activé :

```powershell
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
pytest
```
