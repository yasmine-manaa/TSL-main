"""
Test pour vérifier le format de sortie avec nms=False
Ce test valide que le parsing fonctionne avant de convertir le modèle
"""

import tensorflow as tf
import numpy as np
from PIL import Image
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Créer un modèle de test avec nms=False
print("=" * 70)
print("TEST FORMAT NMS=FALSE")
print("=" * 70)

# Charger le modèle PyTorch original
from ultralytics import YOLO
DETECTOR_PT = os.path.join(BASE_DIR, 'modele-ai-camera/detecteur_main.pt')
TEST_IMAGE = os.path.join(BASE_DIR, 'dictionnaire_DB/yasmaa-entendant/1.png')

print(f"\n1. Export TFLite avec nms=False...")
model = YOLO(DETECTOR_PT)

# Exporter avec nms=False
model.export(
    format='tflite',
    imgsz=384,
    int8=False,
    nms=False,  # Format brut YOLOv8
    simplify=True,
    verbose=False,
)

# Le fichier exporté
import glob
saved_model_dir = os.path.join(BASE_DIR, 'modele-ai-camera/detecteur_main_saved_model')
tflite_files = glob.glob(os.path.join(saved_model_dir, '*.tflite'))
print(f"   Modèle exporté: {tflite_files}")

if tflite_files:
    # Tester l'inférence
    print(f"\n2. Test inférence...")
    interpreter = tf.lite.Interpreter(model_path=tflite_files[0])
    interpreter.allocate_tensors()
    
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print(f"   Input shape: {input_details[0]['shape']}")
    print(f"   Output shape: {output_details[0]['shape']}")
    
    # Préparer l'image
    img = Image.open(TEST_IMAGE).convert('RGB')
    img_resized = img.resize((384, 384))
    img_array = np.array(img_resized, dtype=np.float32) / 255.0
    img_array = np.expand_dims(img_array, axis=0)
    
    # Inférence
    interpreter.set_tensor(input_details[0]['index'], img_array)
    interpreter.invoke()
    output_data = interpreter.get_tensor(output_details[0]['index'])
    
    print(f"   Output shape: {output_data.shape}")
    print(f"   Output min/max: {output_data.min():.4f} / {output_data.max():.4f}")
    
    # Analyser la sortie
    # Format YOLOv8 brut: [batch, 4 + num_classes, num_anchors]
    # Pour 1 classe (main): [1, 5, 3024]
    
    if len(output_data.shape) == 3:
        num_attrs = output_data.shape[1]
        num_detections = output_data.shape[2]
        
        print(f"\n3. Analyse format:")
        print(f"   Attributs: {num_attrs} (4 coords + {num_attrs-4} classes)")
        print(f"   Détections: {num_detections}")
        
        # Chercher les meilleures confidences
        # Les 4 premiers sont [x_center, y_center, width, height]
        # Les suivants sont les scores de classe
        
        best_conf = 0
        best_idx = -1
        
        for i in range(num_detections):
            # Score = max des classes
            class_scores = output_data[0, 4:, i] if num_attrs > 4 else [output_data[0, 4, i]]
            conf = np.max(class_scores)
            
            if conf > best_conf:
                best_conf = conf
                best_idx = i
        
        print(f"\n4. Meilleure détection:")
        print(f"   Index: {best_idx}")
        print(f"   Confiance: {best_conf:.4f}")
        
        if best_idx >= 0 and best_conf > 0.4:
            print(f"   \n✅ SUCCÈS: Détection trouvée avec confiance {best_conf:.4f}")
            print(f"   Le format nms=False fonctionne!")
            
            # Afficher les coordonnées
            x = output_data[0, 0, best_idx]
            y = output_data[0, 1, best_idx]
            w = output_data[0, 2, best_idx]
            h = output_data[0, 3, best_idx]
            print(f"   Coords: x={x:.4f}, y={y:.4f}, w={w:.4f}, h={h:.4f}")
        else:
            print(f"   \n❌ Pas de détection avec confiance > 0.4")
            print(f"   Meilleure conf: {best_conf:.4f}")
            
            # Afficher top 5 quand même
            print(f"   Top 5 confiances:")
            all_confs = []
            for i in range(min(5, num_detections)):
                class_scores = output_data[0, 4:, i] if num_attrs > 4 else [output_data[0, 4, i]]
                conf = np.max(class_scores)
                all_confs.append((conf, i))
            
            all_confs.sort(reverse=True)
            for conf, idx in all_confs[:5]:
                x = output_data[0, 0, idx]
                y = output_data[0, 1, idx]
                print(f"     [{idx}] conf={conf:.6f}, x={x:.4f}, y={y:.4f}")

print("\n" + "=" * 70)
