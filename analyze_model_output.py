import tensorflow as tf
import numpy as np
import os

print("=" * 70)
print("ANALYSE DES MODÈLES YOLOv8 - DÉTECTEUR ET CLASSIFIEUR")
print("=" * 70)

# Chemin vers les modèles
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DETECTOR_PATH = os.path.join(BASE_DIR, 'assets/models/detecteur_main_float32.tflite')
CLASSIFIER_PATH = os.path.join(BASE_DIR, 'assets/models/classifieur_signe_float32.tflite')

print(f"Répertoire: {BASE_DIR}")
print(f"Détecteur: {DETECTOR_PATH}")
print(f"Classifieur: {CLASSIFIER_PATH}")

# 1. Analyser le DÉTECTEUR
print("\n" + "=" * 70)
print("1. DÉTECTEUR: detecteur_main_float32.tflite")
print("=" * 70)

try:
    interpreter = tf.lite.Interpreter(model_path=DETECTOR_PATH)
    interpreter.allocate_tensors()
    
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print("\nINPUT:")
    for inp in input_details:
        print(f"  Shape: {inp['shape']}")
        print(f"  Dtype: {inp['dtype']}")
        print(f"  Name: {inp['name']}")
    
    print("\nOUTPUT:")
    for out in output_details:
        print(f"  Shape: {out['shape']}")
        print(f"  Dtype: {out['dtype']}")
        print(f"  Name: {out['name']}")
    
    # Test avec une image aléatoire
    print("\n--- TEST INFÉRENCE AVEC IMAGE ALÉATOIRE ---")
    input_shape = input_details[0]['shape']
    random_input = np.random.random(input_shape).astype(np.float32)
    
    interpreter.set_tensor(input_details[0]['index'], random_input)
    interpreter.invoke()
    
    for out in output_details:
        output_data = interpreter.get_tensor(out['index'])
        print(f"\nOutput shape: {output_data.shape}")
        print(f"Output min: {output_data.min():.6f}")
        print(f"Output max: {output_data.max():.6f}")
        print(f"Output mean: {output_data.mean():.6f}")
        
        # Afficher les 10 premières valeurs
        print(f"\nPremières 10 valeurs (aplati):")
        flat = output_data.flatten()
        for i in range(min(10, len(flat))):
            print(f"  [{i}]: {flat[i]:.6f}")
        
        # Si la sortie est [1, 7, 3024], analyser la structure
        if len(output_data.shape) == 3 and output_data.shape[1] == 7:
            print(f"\nStructure YOLOv8 détectée: [batch, 7, num_detections]")
            print(f"7 attributs par détection (probablement: x, y, w, h, conf, class, ?)")
            
            # Analyser les 5 meilleures détections par confiance
            # Format typique YOLOv8 NMS: [x_center, y_center, width, height, confidence, class_id, ...]
            if output_data.shape[2] == 3024:
                # Extraire les confiances (index 4)
                confidences = output_data[0, 4, :]
                top_indices = np.argsort(confidences)[-5:][::-1]
                
                print(f"\nTop 5 détections par confiance:")
                for idx in top_indices:
                    row = output_data[0, :, idx]
                    print(f"  Index {idx}: [{row[0]:.4f}, {row[1]:.4f}, {row[2]:.4f}, {row[3]:.4f}, {row[4]:.4f}, {row[5]:.4f}, {row[6]:.4f}]")
                    print(f"    -> x={row[0]:.4f}, y={row[1]:.4f}, w={row[2]:.4f}, h={row[3]:.4f}, conf={row[4]:.4f}, class={row[5]:.4f}")

except Exception as e:
    print(f"Erreur détecteur: {e}")
    import traceback
    traceback.print_exc()

# 2. Analyser le CLASSIFIEUR
print("\n" + "=" * 70)
print("2. CLASSIFIEUR: classifieur_signe_float32.tflite")
print("=" * 70)

try:
    interpreter2 = tf.lite.Interpreter(model_path=CLASSIFIER_PATH)
    interpreter2.allocate_tensors()
    
    input_details = interpreter2.get_input_details()
    output_details = interpreter2.get_output_details()
    
    print("\nINPUT:")
    for inp in input_details:
        print(f"  Shape: {inp['shape']}")
        print(f"  Dtype: {inp['dtype']}")
        print(f"  Name: {inp['name']}")
    
    print("\nOUTPUT:")
    for out in output_details:
        print(f"  Shape: {out['shape']}")
        print(f"  Dtype: {out['dtype']}")
        print(f"  Name: {out['name']}")
    
    # Test avec une image aléatoire
    print("\n--- TEST INFÉRENCE AVEC IMAGE ALÉATOIRE ---")
    input_shape = input_details[0]['shape']
    random_input = np.random.random(input_shape).astype(np.float32)
    
    interpreter2.set_tensor(input_details[0]['index'], random_input)
    interpreter2.invoke()
    
    for out in output_details:
        output_data = interpreter2.get_tensor(out['index'])
        print(f"\nOutput shape: {output_data.shape}")
        print(f"Output min: {output_data.min():.6f}")
        print(f"Output max: {output_data.max():.6f}")
        print(f"Output mean: {output_data.mean():.6f}")
        
        # Si sortie [1, 26], c'est les probabilités pour 26 classes
        if len(output_data.shape) == 2 and output_data.shape[1] == 26:
            print(f"\n26 classes détectées (probabilités)")
            print(f"Top 5 classes:")
            top_indices = np.argsort(output_data[0])[-5:][::-1]
            for idx in top_indices:
                print(f"  Classe {idx}: {output_data[0, idx]:.6f}")

except Exception as e:
    print(f"Erreur classifieur: {e}")
    import traceback
    traceback.print_exc()

print("\n" + "=" * 70)
print("FIN DE L'ANALYSE")
print("=" * 70)
