# Intégration Modèle IA LST - Guide Backend API

## Pourquoi un backend ?

Votre modèle IA (`detecteur_main.pt` + `classifieur_signe.pt`) est entraîné avec **PyTorch / YOLO (Ultralytics)** et utilise **OpenCV**. Ces bibliothèques ne fonctionnent pas directement sur mobile Flutter.

La solution la plus rapide et fiable est d'exposer votre modèle via une **API Flask** (Python) et de faire communiquer l'app Flutter avec cette API par HTTP.

---

## Architecture

```
┌─────────────────┐      HTTP POST (image)      ┌──────────────────┐
│   App Flutter   │  ─────────────────────────>  │  Backend Flask   │
│  (caméra live)  │                            │  (Python + YOLO) │
│                 │  <─────────────────────────  │                  │
│                 │      JSON (signe, conf)      │                  │
└─────────────────┘                            └──────────────────┘
```

---

## Étape 1 : Lancer le Backend Flask

### 1.1 Installer les dépendances Python

```bash
cd backend
pip install -r requirements.txt
```

> Conseil : utilisez un environnement virtuel (`python -m venv venv`)

### 1.2 Lancer le serveur

```bash
python api.py
```

Le serveur démarre sur `http://0.0.0.0:5000`.

### 1.3 Tester rapidement

```bash
curl http://localhost:5000/health
```

Réponse attendue : `{"status":"ok","models_loaded":true}`

---

## Étape 2 : Configurer l'App Flutter

### 2.1 Récupérer les dépendances

```bash
flutter pub get
```

Les packages `http` et `http_parser` ont été ajoutés au `pubspec.yaml`.

### 2.2 Adapter l'adresse du backend

Ouvrez `lib/services/backend_ai_service.dart` et modifiez `_baseUrl` selon votre cas :

| Cas d'usage | Valeur de `_baseUrl` |
|-------------|----------------------|
| Émulateur Android | `http://10.0.2.2:5000` |
| Simulateur iOS | `http://127.0.0.1:5000` |
| Vrai téléphone (même WiFi) | `http://IP_DE_VOTRE_PC:5000` |

> Pour trouver l'IP de votre PC : `ipconfig` (Windows) ou `ifconfig` (Mac/Linux)

---

## Étape 3 : Utiliser l'application

### Mode "Capture + Analyse" (page `ai_recognition.dart`)

1. Ouvrez l'app → Accueil → "Reconnaissance IA Temps Réel"
2. La caméra s'affiche
3. **Capturez une photo**
4. Appuyez sur **Analyser**
5. L'image est envoyée au backend → le signe détecté s'affiche avec sa confiance

### Mode "Temps Réel" (page `ai_realtime_backend_page.dart`)

1. Ouvrez l'app → Accueil → "Reconnaissance IA Temps Réel"
2. Appuyez sur **▶ DÉMARRER**
3. L'app capture automatiquement une photo toutes les **700 ms** et l'envoie au backend
4. Le signe détecté apparaît en overlay sur la caméra
5. Appuyez sur **⏹ ARRÊTER** pour stopper

---

## Dépannage

### "Backend IA injoignable"

- Vérifiez que `python api.py` tourne bien dans un terminal
- Vérifiez le pare-feu Windows : autorisez le port 5000
- Assurez-vous que le téléphone et le PC sont sur le **même réseau WiFi**
- Testez l'URL depuis le navigateur du téléphone : `http://IP:5000/health`

### "Aucune main détectée"

- Assurez-vous que votre main est bien visible et éclairée
- Le modèle `detecteur_main.pt` doit être présent dans `modele-ai-camera/`

### Latence trop élevée en temps réel

- Le backend fait 2 inférences YOLO (détection + classification) → c'est lourd
- Augmentez l'intervalle dans `ai_realtime_backend_page.dart` :
  ```dart
  final Duration _detectionInterval = const Duration(milliseconds: 1200);
  ```
- Utilisez une résolution plus basse pour la caméra : `ResolutionPreset.low`

---

## Prochaines étapes possibles

1. **Déployer le backend sur un serveur cloud** (Render, Railway, AWS, etc.) pour ne plus dépendre du PC local
2. **Convertir les modèles en TFLite** pour une inférence 100 % offline sur mobile (plus complexe)
3. **Ajouter un mapping signe → mot** : actuellement le modèle détecte des lettres/chiffres (A-Z, 0-9). Vous pouvez enrichir `labels.txt` et le backend pour retourner aussi le mot correspondant.

---

## Fichiers créés / modifiés

| Fichier | Rôle |
|---------|------|
| `backend/api.py` | Serveur Flask avec endpoint `/detect` |
| `backend/requirements.txt` | Dépendances Python |
| `lib/services/backend_ai_service.dart` | Client HTTP Flutter |
| `lib/pages/ai_realtime_backend_page.dart` | Page temps réel |
| `lib/pages/ai_recognition.dart` | Mode capture (analyse via backend) |
| `lib/pages/home_page.dart` | Navigation vers la nouvelle page |
| `pubspec.yaml` | Ajout de `http` et `http_parser` |
