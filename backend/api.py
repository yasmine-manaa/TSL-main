import os
import io
import cv2
import numpy as np
from flask import Flask, request, jsonify
from flask_cors import CORS
from ultralytics import YOLO
from PIL import Image

app = Flask(__name__)
CORS(app)

# --- CONFIGURATION ---
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
# Remonter au dossier parent pour trouver les modèles
PROJECT_DIR = os.path.dirname(BASE_DIR)
MODELS_DIR = os.path.join(PROJECT_DIR, 'modele-ai-camera')

PATH_DETECTOR = os.path.join(MODELS_DIR, 'detecteur_main.pt')
PATH_CLASSIFIER = os.path.join(MODELS_DIR, 'classifieur_signe.pt')

# Vérifier l'existence des modèles
print(f"Detecteur: {PATH_DETECTOR} (exists: {os.path.exists(PATH_DETECTOR)})")
print(f"Classifieur: {PATH_CLASSIFIER} (exists: {os.path.exists(PATH_CLASSIFIER)})")

# 1. Chargement des modèles
print("Wait... Chargement des modèles IA...")
detector = YOLO(PATH_DETECTOR)
classifier = YOLO(PATH_CLASSIFIER)
print("Modèles chargés avec succès !")


def detect_and_classify(image_np):
    """
    Applique la logique camera-1bbox.py sur une image numpy BGR.
    Retourne un dict avec les résultats.
    """
    h_frame, w_frame, _ = image_np.shape

    # 1. Détection des mains
    results_det = detector(image_np, conf=0.4, verbose=False)
    boxes = results_det[0].boxes.xyxy.cpu().numpy()

    if len(boxes) == 0:
        return {
            'detected': False,
            'sign': None,
            'confidence': 0.0,
            'message': 'Aucune main détectée'
        }

    # --- LOGIQUE D'ENGLOBEMENT (Merge Bounding Boxes) ---
    x1_min = np.min(boxes[:, 0])
    y1_min = np.min(boxes[:, 1])
    x2_max = np.max(boxes[:, 2])
    y2_max = np.max(boxes[:, 3])

    # --- CALCUL DU CROP CARRÉ AVEC PADDING ---
    w_box = x2_max - x1_min
    h_box = y2_max - y1_min

    # Côté le plus long + 30% de marge
    side = int(max(w_box, h_box) * 1.3)

    # Centre de la zone détectée
    cx, cy = (x1_min + x2_max) // 2, (y1_min + y2_max) // 2

    # Coordonnées du carré final
    fx1 = max(0, int(cx - side // 2))
    fy1 = max(0, int(cy - side // 2))
    fx2 = min(w_frame, int(fx1 + side))
    fy2 = min(h_frame, int(fy1 + side))

    # Découpe
    hand_crop = image_np[fy1:fy2, fx1:fx2]

    if hand_crop.size == 0:
        return {
            'detected': False,
            'sign': None,
            'confidence': 0.0,
            'message': 'Crop vide'
        }

    # 2. Classification du signe
    results_cls = classifier(hand_crop, verbose=False)

    prob = results_cls[0].probs.top1conf.item()
    index = results_cls[0].probs.top1
    label = results_cls[0].names[index]

    return {
        'detected': True,
        'sign': str(label),
        'confidence': float(prob),
        'bbox': {
            'x1': int(fx1),
            'y1': int(fy1),
            'x2': int(fx2),
            'y2': int(fy2)
        },
        'message': 'Signe détecté'
    }


@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok', 'models_loaded': True})


@app.route('/detect', methods=['POST'])
def detect():
    try:
        if 'image' not in request.files:
            return jsonify({'error': 'Aucune image fournie (attendu: form-data avec key="image")'}), 400

        file = request.files['image']
        if file.filename == '':
            return jsonify({'error': 'Fichier vide'}), 400

        # Lire l'image avec PIL
        img_bytes = file.read()
        pil_img = Image.open(io.BytesIO(img_bytes)).convert('RGB')

        # Convertir en numpy BGR pour OpenCV
        image_np = cv2.cvtColor(np.array(pil_img), cv2.COLOR_RGB2BGR)

        # Inférence
        result = detect_and_classify(image_np)

        return jsonify(result)

    except Exception as e:
        print(f"Erreur /detect: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/detect_base64', methods=['POST'])
def detect_base64():
    """
    Alternative: recevoir une image en base64 dans un JSON.
    """
    try:
        data = request.get_json()
        if not data or 'image_base64' not in data:
            return jsonify({'error': 'Champ image_base64 manquant'}), 400

        import base64
        img_bytes = base64.b64decode(data['image_base64'])
        pil_img = Image.open(io.BytesIO(img_bytes)).convert('RGB')
        image_np = cv2.cvtColor(np.array(pil_img), cv2.COLOR_RGB2BGR)

        result = detect_and_classify(image_np)
        return jsonify(result)

    except Exception as e:
        print(f"Erreur /detect_base64: {e}")
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    # Écouter sur toutes les interfaces pour permettre l'accès depuis mobile/émulateur
    app.run(host='0.0.0.0', port=5000, debug=False)
