import tensorflow as tf
import numpy as np
from PIL import Image
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DETECTOR_PATH = os.path.join(BASE_DIR, 'assets/models/detecteur_main_float32.tflite')
TEST_IMAGE = os.path.join(BASE_DIR, 'dictionnaire_DB/yasmaa-entendant/1.png')

print("=" * 70)
print("TEST DU DÉTECTEUR AVEC IMAGE RÉELLE")
print("=" * 70)
print(f"Image test: {TEST_IMAGE}")

try:
    # Charger l'image
    img = Image.open(TEST_IMAGE).convert('RGB')
    img = img.resize((384, 384), Image.Resampling.LANCZOS)
    img_array = np.array(img, dtype=np.float32) / 255.0
    img_array = np.expand_dims(img_array, axis=0)  # [1, 384, 384, 3]
    
    print(f"Image shape: {img_array.shape}")
    print(f"Image min/max: {img_array.min():.4f} / {img_array.max():.4f}")
    
    # Charger le modèle
    interpreter = tf.lite.Interpreter(model_path=DETECTOR_PATH)
    interpreter.allocate_tensors()
    
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    # Inférence
    interpreter.set_tensor(input_details[0]['index'], img_array)
    interpreter.invoke()
    
    output_data = interpreter.get_tensor(output_details[0]['index'])
    print(f"\nOutput shape: {output_data.shape}")
    
    # Analyser les détections
    confidences = output_data[0, 4, :]
    max_conf = confidences.max()
    print(f"Confidence max: {max_conf:.6f}")
    
    # Top 10 détections
    top_indices = np.argsort(confidences)[-10:][::-1]
    print(f"\nTop 10 détections:")
    for idx in top_indices:
        row = output_data[0, :, idx]
        print(f"  [{idx}] conf={row[4]:.6f} | x={row[0]:.4f}, y={row[1]:.4f}, w={row[2]:.4f}, h={row[3]:.4f}, class={row[5]:.4f}")
    
    # Compter combien ont conf > 0.1
    count_01 = np.sum(confidences > 0.1)
    count_05 = np.sum(confidences > 0.5)
    print(f"\nNombre de détections avec conf > 0.1: {count_01}")
    print(f"Nombre de détections avec conf > 0.5: {count_05}")
    
except Exception as e:
    print(f"Erreur: {e}")
    import traceback
    traceback.print_exc()
