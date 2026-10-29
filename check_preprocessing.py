import numpy as np
from PIL import Image
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
TEST_IMAGE = os.path.join(BASE_DIR, 'dictionnaire_DB/yasmaa-entendant/1.png')

print("=" * 70)
print("VÉRIFICATION DU PREPROCESSING")
print("=" * 70)

# Charger l'image
img = Image.open(TEST_IMAGE).convert('RGB')
print(f"Image originale: {img.size} (mode: {img.mode})")

# Méthode 1: Division par 255 (ce que je fais en Flutter)
img_array1 = np.array(img, dtype=np.float32) / 255.0
print(f"\nMéthode 1 (division par 255):")
print(f"  Min: {img_array1.min():.6f}, Max: {img_array1.max():.6f}, Mean: {img_array1.mean():.6f}")

# Méthode 2: Normalisation Ultralytics (divide by 255 et peut-être autre chose)
# Ultralytics utilise généralement: img = img / 255.0
# Mais parfois aussi: img = (img - mean) / std

# Vérifier si Ultralytics fait un preprocessing spécial
from ultralytics import YOLO
DETECTOR_PATH = os.path.join(BASE_DIR, 'assets/models/detecteur_main_float32.tflite')
model = YOLO(DETECTOR_PATH, task='detect')

# Accéder au preprocessing interne
if hasattr(model, 'model'):
    print(f"\nModèle: {model.model}")
    if hasattr(model.model, 'args'):
        print(f"Args: {model.model.args}")

# Test avec différentes méthodes de preprocessing
print(f"\nTest avec preprocessing Ultralytics:")
results = model(img, conf=0.4, verbose=False)
if len(results) > 0 and results[0].boxes is not None and len(results[0].boxes) > 0:
    print(f"  Détections: {len(results[0].boxes)}")
    r = results[0]
    print(f"  xyxy (pixels): {r.boxes.xyxy}")
    print(f"  conf: {r.boxes.conf}")
    print(f"  cls: {r.boxes.cls}")
    print(f"  orig_shape: {r.orig_shape}")
else:
    print(f"  Aucune détection")
