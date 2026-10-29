"""
Inspecter exactement ce que fait Ultralytics pour le preprocessing
"""

import numpy as np
from PIL import Image
from ultralytics import YOLO
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DETECTOR_PATH = os.path.join(BASE_DIR, 'assets/models/detecteur_main_float32.tflite')
TEST_IMAGE = os.path.join(BASE_DIR, 'dictionnaire_DB/yasmaa-entendant/1.png')

print("=" * 70)
print("INSPECTION ULTRALYTICS - PREPROCESSING EXACT")
print("=" * 70)

# Charger l'image
img = Image.open(TEST_IMAGE).convert('RGB')
print(f"Image originale: {img.size}")

# Charger le modèle
model = YOLO(DETECTOR_PATH, task='detect')

# Voir les arguments du modèle
print(f"\nArgs du modèle:")
if hasattr(model, 'model') and hasattr(model.model, 'args'):
    args = model.model.args
    print(f"  imgsz: {args.imgsz}")
    print(f"  task: {args.task}")
    print(f"  single_cls: {args.single_cls}")

# Préprocessing manuel comme Ultralytics le fait
# 1. Redimensionnement
from ultralytics.data.augment import LetterBox

print(f"\nTest avec LetterBox d'Ultralytics:")
letterbox = LetterBox(new_shape=(384, 384))
img_array = np.array(img)
img_processed = letterbox(image=img_array)
print(f"  Shape après LetterBox: {img_processed.shape}")
print(f"  Min/Max: {img_processed.min():.4f} / {img_processed.max():.4f}")

# 2. Normalisation
img_normalized = img_processed / 255.0
print(f"  Après /255: min={img_normalized.min():.4f}, max={img_normalized.max():.4f}")

# 3. Transpose pour BHWC -> BCHW (comme PyTorch)
img_transposed = np.transpose(img_normalized, (2, 0, 1))
print(f"  Après transpose (C,H,W): {img_transposed.shape}")

# Inférence avec le tensor préparé manuellement
import tensorflow as tf
interpreter = tf.lite.Interpreter(model_path=DETECTOR_PATH)
interpreter.allocate_tensors()

# Préparer l'input
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# Voir le format attendu
print(f"\nFormat attendu par TFLite:")
print(f"  Input shape: {input_details[0]['shape']}")
print(f"  Input dtype: {input_details[0]['dtype']}")

# Le modèle attend [1, 384, 384, 3] (NHWC)
img_input = np.expand_dims(img_normalized, axis=0).astype(np.float32)
print(f"  Mon input: {img_input.shape}, dtype={img_input.dtype}")

interpreter.set_tensor(input_details[0]['index'], img_input)
interpreter.invoke()
output_data = interpreter.get_tensor(output_details[0]['index'])

# Parsing
confidences = output_data[0, 4, :]
max_conf = confidences.max()
print(f"\nRésultat avec mon preprocessing:")
print(f"  Max confidence: {max_conf:.6f}")

if max_conf > 0.4:
    idx = confidences.argmax()
    row = output_data[0, :, idx]
    print(f"  Détection: x1={row[0]:.4f}, y1={row[1]:.4f}, x2={row[2]:.4f}, y2={row[3]:.4f}, conf={row[4]:.4f}")
else:
    print(f"  Pas de détection (seuil 0.4)")

# Comparer avec Ultralytics
print(f"\nComparaison Ultralytics:")
results = model(img, conf=0.4, verbose=False)
if len(results) > 0 and results[0].boxes is not None:
    print(f"  Détections: {len(results[0].boxes)}")
    print(f"  Conf: {results[0].boxes.conf}")
else:
    print(f"  Aucune détection")
