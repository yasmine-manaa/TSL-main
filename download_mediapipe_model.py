"""
Télécharge le modèle MediaPipe Hands TFLite officiel
"""

import urllib.request
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_URL = "https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/latest/hand_landmarker.task"
OUTPUT_PATH = os.path.join(BASE_DIR, "assets", "models", "hand_landmarker.task")

print("Téléchargement du modèle MediaPipe Hands...")
print(f"URL: {MODEL_URL}")
print(f"Destination: {OUTPUT_PATH}")

try:
    urllib.request.urlretrieve(MODEL_URL, OUTPUT_PATH)
    print(f"✅ Modèle téléchargé avec succès!")
    print(f"Taille: {os.path.getsize(OUTPUT_PATH) / 1024 / 1024:.1f} MB")
except Exception as e:
    print(f"❌ Erreur: {e}")
    print("Alternative: Utiliser le modèle détecteur_main_float32.tflite existant")
