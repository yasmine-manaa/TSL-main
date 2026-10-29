# Intégration TFLite Offline — Détection LST 100% On-Device

Ce guide explique comment exécuter la détection et la reconnaissance de la Langue des Signes Tunisienne **directement sur le téléphone**, sans serveur backend et sans connexion internet.

## Architecture

```
┌─────────────────┐     ┌──────────────────────┐     ┌─────────────────┐
│  CameraImage    │────▶│  TfliteAIService     │────▶│  Résultat (LST) │
│  (YUV420)       │     │  (Flutter + TFLite)  │     │  Affichage UI   │
└─────────────────┘     └──────────────────────┘     └─────────────────┘
```

**Pipeline par frame :**
1. **Prétraitement** : YUV420 → RGB → resize 640×640
2. **Détection** : Modèle `detecteur_main.tflite` (YOLOv8) → bounding boxes des mains
3. **Merge + Crop** : Fusion des boxes + marge 30% (même logique `camera-1bbox.py`)
4. **Classification** : Modèle `classifieur_signe.tflite` (YOLOv8-cls) → label du signe

## Fichiers créés / modifiés

| Fichier | Rôle |
|---------|------|
| `modele-ai-camera/convert_to_tflite.py` | Conversion `.pt` → `.tflite` |
| `lib/services/tflite_ai_service.dart` | Service Flutter TFLite on-device |
| `lib/pages/ai_realtime_offline_page.dart` | Page temps réel offline |
| `pubspec.yaml` | Ajout dépendance `tflite_flutter` + assets `.tflite` |
| `lib/pages/home_page.dart` | Navigation vers la page offline |

## Prérequis

- **Flutter** ≥ 3.16
- **Python** ≥ 3.9 avec `ultralytics` et `tensorflow`
- Modèles sources : `detecteur_main.pt`, `classifieur_signe.pt`

## Étape 1 — Conversion des modèles

```bash
cd modele-ai-camera
python convert_to_tflite.py
```

**Sortie attendue :**
- `detecteur_main.tflite` (~ 10–30 MB)
- `classifieur_signe.tflite` (~ 5–15 MB)

> Si vous utilisez **ultralytics ≥ 8.0.200**, l'export intègre automatiquement le NMS dans le graphe TFLite (`nms=True`). Sinon le post-processing NMS est fait en Dart.

## Étape 2 — Copie des assets

```bash
cp modele-ai-camera/detecteur_main.tflite     assets/models/
cp modele-ai-camera/classifieur_signe.tflite assets/models/
```

Vérifiez que `pubspec.yaml` contient :

```yaml
assets:
  - assets/models/detecteur_main.tflite
  - assets/models/classifieur_signe.tflite
  - assets/models/labels.txt
```

## Étape 3 — Configuration Android (tflite_flutter)

**`android/app/build.gradle`** — ajoutez dans `defaultConfig` :

```gradle
android {
    defaultConfig {
        minSdkVersion 21   // obligatoire pour TFLite
    }
}
```

**`android/app/src/main/AndroidManifest.xml`** — si vous utilisez la caméra :

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="true" />
```

## Étape 4 — Lancer l'application

```bash
flutter pub get
flutter run
```

## Comparaison Backend vs Offline

| Critère | Backend Flask | TFLite Offline |
|---------|--------------|----------------|
| Connexion internet | ❌ Requise | ✅ Pas nécessaire |
| Latence | 200–800 ms (réseau) | 50–150 ms (local) |
| Consommation batterie | Faible (envoi HTTP) | Élevée (inférence CPU/GPU) |
| Taille APK | ~ +20 MB | ~ +40 MB (modèles inclus) |
| Précision | Identique au modèle source | Identique (float32) ou légère perte (INT8) |

## Dépannage

### `Failed to load model` ou `Interpreter.fromAsset` crash
- Vérifiez que les fichiers `.tflite` sont bien listés dans `pubspec.yaml`.
- Faites `flutter clean && flutter pub get`.
- Sur Android, vérifiez `minSdkVersion 21`.

### Très lent / frame drop
- Baissez la résolution caméra : `ResolutionPreset.low` ou `medium`.
- Diminuez la fréquence d'analyse : augmentez l'intervalle du timer ou sautez des frames dans `startImageStream`.
- Activez la quantization INT8 dans `convert_to_tflite.py` (`int8=True`) pour un modèle 4× plus rapide.

### Mauvaise précision après conversion
- Vérifiez que `labels.txt` correspond exactement à l'ordre des classes du modèle.
- Assurez-vous que le preprocessing (normalisation `/255.0`) correspond à l'entraînement.
- Si vous utilisez INT8, la perte de précision est normale ; repassez en float32.

### `camera` plugin + `tflite_flutter` crash sur iOS
- Assurez-vous que `Podfile` a `platform :ios, '12.0'` minimum.
- Ajoutez les permissions caméra dans `Info.plist`.

## Prochaines améliorations

1. **GPU / NNAPI** : utiliser `GpuDelegateV2` ou `NnApiDelegate` pour accélérer l'inférence sur Android.
2. **Multi-thread** : le service utilise déjà 4 threads pour le détecteur ; ajustez selon le hardware.
3. **Cache des crops** : éviter de re-classifier si la position des mains n'a pas beaucoup changé entre deux frames.
4. **Quantization INT8** : convertir en INT8 avec calibration (dataset représentatif) pour réduire taille + latence.

## Références

- [tflite_flutter](https://pub.dev/packages/tflite_flutter)
- [YOLOv8 Export TFLite](https://docs.ultralytics.com/modes/export/)
