import tensorflow as tf
import numpy as np
from ultralytics import YOLO
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DETECTOR_PATH = os.path.join(BASE_DIR, 'assets/models/detecteur_main_float32.tflite')

print("=" * 70)
print("ANALYSE DU FORMAT ULTRALYTICS TFLITE")
print("=" * 70)

# Charger avec Ultralytics
print("\n1. Chargement avec Ultralytics YOLO:")
model = YOLO(DETECTOR_PATH, task='detect')

# Créer une image de test
test_img = np.random.randint(0, 255, (480, 640, 3), dtype=np.uint8)

# Inférence avec Ultralytics
results = model(test_img, conf=0.4, verbose=False)

print(f"Nombre de résultats: {len(results)}")
if len(results) > 0:
    r = results[0]
    print(f"Boxes: {r.boxes}")
    if r.boxes is not None:
        print(f"Nombre de boîtes: {len(r.boxes)}")
        print(f"Format xyxy: {r.boxes.xyxy}")
        print(f"Format conf: {r.boxes.conf}")
        print(f"Format cls: {r.boxes.cls}")

# Comparer avec inférence TFLite brute
print("\n2. Comparaison avec TFLite brut:")
interpreter = tf.lite.Interpreter(model_path=DETECTOR_PATH)
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# Préparer l'input
img_resized = np.random.random((1, 384, 384, 3)).astype(np.float32)

interpreter.set_tensor(input_details[0]['index'], img_resized)
interpreter.invoke()

output_data = interpreter.get_tensor(output_details[0]['index'])
print(f"Output shape: {output_data.shape}")
print(f"Output sample (first detection):")
for i in range(7):
    print(f"  Attr {i}: {output_data[0][i][0]:.6f}")
