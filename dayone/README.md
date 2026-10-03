# DayOne

Prototype hackathon : application mobile pour sages-femmes permettant, à terme, de numériser
les pages d'un registre maternel papier en dossier structuré (IA, offline-first, vérification
humaine, synchronisation).

**État actuel : squelette technique uniquement** (aucune fonctionnalité métier).

```
dayone/
├── backend/   # API REST FastAPI (Python 3.11+, SQLAlchemy, PostgreSQL)
└── mobile/    # Application Flutter (Android)
```

## Prérequis

- Python 3.11+
- Flutter (stable) + Android SDK (Android Studio)
- Un émulateur Android ou un téléphone Android en mode développeur
- PostgreSQL (pas requis pour l'étape actuelle)

## 1. Lancer le backend

```powershell
cd backend
python -m venv venv
.\venv\Scripts\Activate.ps1          # macOS / Linux : source venv/bin/activate
pip install -r requirements.txt
Copy-Item .env.example .env          # macOS / Linux : cp .env.example .env
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Vérifier : http://localhost:8000/health → `{"status": "ok"}`

> `--host 0.0.0.0` est nécessaire pour qu'un téléphone physique puisse joindre l'API.
> Avec l'émulateur seul, `uvicorn app.main:app --reload` suffit.

## 2. Lancer l'application Flutter

Dans un second terminal :

```powershell
cd mobile
flutter pub get
flutter run
```

Puis appuyer sur **Test Backend Connection** : le message « Backend connected » doit s'afficher.

### Émulateur Android

Aucune configuration : l'app utilise par défaut `http://10.0.2.2:8000`
(`10.0.2.2` = le PC hôte vu depuis l'émulateur).

### Téléphone Android physique

1. Brancher le téléphone en USB avec le débogage USB activé (ou débogage Wi-Fi).
2. Le téléphone et le PC doivent être sur le **même réseau Wi-Fi**.
3. Trouver l'IP locale du PC : `ipconfig` → « Adresse IPv4 » de la carte Wi-Fi (ex. `192.168.1.42`).
4. Lancer le backend avec `--host 0.0.0.0`.
5. Autoriser le port 8000 dans le pare-feu Windows (PowerShell administrateur) :
   ```powershell
   New-NetFirewallRule -DisplayName "DayOne API 8000" -Direction Inbound -Protocol TCP -LocalPort 8000 -Action Allow
   ```
6. Lancer l'app avec l'IP du PC :
   ```powershell
   flutter run --dart-define=API_BASE_URL=http://192.168.1.42:8000
   ```

## Tests

```powershell
cd backend; pytest
cd mobile;  flutter test
```
