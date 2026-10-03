# DayOne — Mobile (Flutter)

Application Android du prototype DayOne. Pour l'instant : un écran d'accueil avec un bouton
**Test Backend Connection** qui appelle `GET /health`.

## Lancement

```powershell
cd mobile
flutter pub get
flutter run
```

## URL du backend

L'URL est définie dans `lib/core/config/app_config.dart` et peut être surchargée au lancement :

| Cible                     | Commande                                                              |
|---------------------------|-----------------------------------------------------------------------|
| Émulateur Android (défaut) | `flutter run` → `http://10.0.2.2:8000`                               |
| Téléphone Android physique | `flutter run --dart-define=API_BASE_URL=http://<IP_DU_PC>:8000`      |

`10.0.2.2` est l'alias de la machine hôte vu depuis l'émulateur Android.

Pour un téléphone physique : le téléphone et le PC doivent être sur le **même réseau Wi-Fi**,
le backend doit être lancé avec `--host 0.0.0.0`, et le pare-feu Windows doit autoriser le port 8000.
Trouver l'IP du PC avec `ipconfig` (ligne « Adresse IPv4 » de la carte Wi-Fi).

## Structure

```
lib/
├── main.dart                 # Point d'entrée
├── app/                      # MaterialApp, thème
├── core/                     # Config, réseau (ApiClient), utilitaires transverses
├── features/                 # Une feature = un dossier (home/ pour l'instant)
└── shared/                   # Widgets réutilisables
```
