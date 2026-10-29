import tensorflow as tf
import numpy as np
from ultralytics import YOLO
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DETECTOR_PATH = os.path.join(BASE_DIR, 'assets/models/detecteur_main_float32.tflite')
TEST_IMAGE = os.path.join(BASE_DIR, 'dictionnaire_DB/yasmaa-entendant/1.png')

print("=" * 70)
print("DEBUG PARSING ULTRALYTICS")
print("=" * 70)

# Charger l'image
from PIL import Image
img = Image.open(TEST_IMAGE).convert('RGB')
img_array = np.array(img, dtype=np.float32) / 255.0

print(f"Image originale: {img_array.shape}")

# 1. Test avec Ultralytics
print("\n1. Test avec Ultralytics YOLO:")
model = YOLO(DETECTOR_PATH, task='detect')
results = model(img_array, conf=0.4, verbose=False)

if len(results) > 0 and results[0].boxes is not None and len(results[0].boxes) > 0:
    r = results[0]
    print(f"Nombre de boîtes: {len(r.boxes)}")
    print(f"xyxy (pixels): {r.boxes.xyxy}")
    print(f"conf: {r.boxes.conf}")
    print(f"cls: {r.boxes.cls}")
    print(f"orig_shape: {r.orig_shape}")
else:
    print("Aucune détection avec Ultralytics")

# 2. Test avec TFLite brut pour voir les valeurs brutes
print("\n2. Test avec TFLite brut:")
interpreter = tf.lite.Interpreter(model_path=DETECTOR_PATH)
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# Redimensionner comme Ultralytics le fait
from PIL import Image
img_resized = img.resize((384, 384), Image.Resampling.LANCZOS)
img_array_resized = np.array(img_resized, dtype=np.float32) / 255.0
img_array_resized = np.expand_dims(img_array_resized, axis=0)

print(f"Image redimensionnée: {img_array_resized.shape}")

interpreter.set_tensor(input_details[0]['index'], img_array_resized)
interpreter.invoke()

output_data = interpreter.get_tensor(output_details[0]['index'])
print(f"Output shape: {output_data.shape}")

# Afficher les 10 meilleures détections par confiance
confidences = output_data[0, 4, :]
top_indices = np.argsort(confidences)[-10:][::-1]

print(f"\nTop 10 détections par confiance (brut):")
for idx in top_indices:
    row = output_data[0, :, idx]
    print(f"  [{idx}] conf={row[4]:.6f} | x1={row[0]:.4f}, y1={row[1]:.4f}, x2={row[2]:.4f}, y2={row[3]:.4f}, class={row[5]:.4f}")
