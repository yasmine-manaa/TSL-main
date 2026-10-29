"""
Test unitaire complet pour vérifier l'équivalence entre Ultralytics et TFLite brut
Ce test reproduit exactement ce que fait le code Flutter pour identifier le problème
"""

import tensorflow as tf
import numpy as np
from PIL import Image
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DETECTOR_PATH = os.path.join(BASE_DIR, 'assets/models/detecteur_main_float32.tflite')
TEST_IMAGE = os.path.join(BASE_DIR, 'dictionnaire_DB/yasmaa-entendant/1.png')

print("=" * 70)
print("TEST ÉQUIVALENCE FLUTTER - ANALYSE COMPLÈTE")
print("=" * 70)

# 1. Charger l'image originale
img = Image.open(TEST_IMAGE).convert('RGB')
orig_w, orig_h = img.size
print(f"\n1. Image originale: {orig_w}x{orig_h}")

# 2. REPRODUIRE LE PREPROCESSING FLUTTER (letterbox)
max_dim = max(orig_w, orig_h)
dsize = 384
scale = dsize / max_dim
new_w = int(orig_w * scale)
new_h = int(orig_h * scale)
pad_x = (dsize - new_w) // 2
pad_y = (dsize - new_h) // 2

print(f"\n2. Preprocessing Flutter (letterbox):")
print(f"   Scale: {scale:.4f}")
print(f"   New size: {new_w}x{new_h}")
print(f"   Padding: x={pad_x}, y={pad_y}")

# Redimensionner
img_resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)

# Créer image carrée avec fond gris (114, 114, 114)
img_square = Image.new('RGB', (dsize, dsize), (114, 114, 114))
img_square.paste(img_resized, (pad_x, pad_y))

# Convertir en array normalisé [0-1]
img_array = np.array(img_square, dtype=np.float32) / 255.0
img_array = np.expand_dims(img_array, axis=0)  # [1, 384, 384, 3]

print(f"   Tensor shape: {img_array.shape}")
print(f"   Tensor min/max: {img_array.min():.4f} / {img_array.max():.4f}")

# 3. INFÉRENCE TFLITE
print(f"\n3. Inférence TFLite:")
interpreter = tf.lite.Interpreter(model_path=DETECTOR_PATH)
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

interpreter.set_tensor(input_details[0]['index'], img_array)
interpreter.invoke()

output_data = interpreter.get_tensor(output_details[0]['index'])
print(f"   Output shape: {output_data.shape}")

# 4. PARSING COMME FLUTTER
print(f"\n4. Parsing (format [1, 7, 3024] = [x1, y1, x2, y2, conf, class, ?]):")

boxes = []
cTh = 0.4
num_detections = output_data.shape[2]

for i in range(num_detections):
    x1 = output_data[0, 0, i]
    y1 = output_data[0, 1, i]
    x2 = output_data[0, 2, i]
    y2 = output_data[0, 3, i]
    conf = output_data[0, 4, i]
    
    if conf < cTh:
        continue
    if x2 <= x1 or y2 <= y1:
        continue
    
    # Reprojeter sur l'image originale (comme Flutter)
    x1_no_pad = x1 - pad_x
    y1_no_pad = y1 - pad_y
    x2_no_pad = x2 - pad_x
    y2_no_pad = y2 - pad_y
    
    x1_orig = x1_no_pad / scale
    y1_orig = y1_no_pad / scale
    x2_orig = x2_no_pad / scale
    y2_orig = y2_no_pad / scale
    
    boxes.append({
        'x': x1_orig,
        'y': y1_orig,
        'w': x2_orig - x1_orig,
        'h': y2_orig - y1_orig,
        'conf': conf,
        'raw': [x1, y1, x2, y2, conf, output_data[0, 5, i], output_data[0, 6, i]]
    })

print(f"   Boxes détectées: {len(boxes)}")

if len(boxes) > 0:
    # Prendre la meilleure
    best = max(boxes, key=lambda b: b['conf'])
    print(f"   Meilleure box: conf={best['conf']:.4f}")
    print(f"   Coordonnées originales: x={best['x']:.1f}, y={best['y']:.1f}, w={best['w']:.1f}, h={best['h']:.1f}")
    print(f"   Valeurs brutes: {best['raw']}")
else:
    # Afficher les meilleures confidences brutes
    confidences = output_data[0, 4, :]
    top5 = np.argsort(confidences)[-5:][::-1]
    print(f"   Top 5 confiances brutes:")
    for idx in top5:
        row = output_data[0, :, idx]
        print(f"     [{idx}] conf={row[4]:.6f} | x1={row[0]:.4f}, y1={row[1]:.4f}, x2={row[2]:.4f}, y2={row[3]:.4f}")

# 5. COMPARAISON AVEC ULTRALYTICS
print(f"\n5. Comparaison avec Ultralytics:")
from ultralytics import YOLO
model = YOLO(DETECTOR_PATH, task='detect')
results = model(img, conf=0.4, verbose=False)

if len(results) > 0 and results[0].boxes is not None and len(results[0].boxes) > 0:
    r = results[0]
    print(f"   Ultralytics détections: {len(r.boxes)}")
    print(f"   xyxy: {r.boxes.xyxy}")
    print(f"   conf: {r.boxes.conf}")
else:
    print(f"   Ultralytics: Aucune détection")

print(f"\n6. ANALYSE:")
if len(boxes) == 0 and len(results) > 0 and results[0].boxes is not None and len(results[0].boxes) > 0:
    print("   PROBLÈME: Ultralytics détecte mais TFLite brut non")
    print("   → Le parsing ou le preprocessing est incorrect")
elif len(boxes) > 0:
    print(f"   SUCCÈS: Les deux détectent!")
    print(f"   → Le code Flutter devrait marcher")
else:
    print(f"   Les deux ne détectent pas sur cette image")
    print(f"   → Tester avec une autre image ou la caméra")
