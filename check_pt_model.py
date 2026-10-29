from ultralytics import YOLO
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DETECTOR_PT = os.path.join(BASE_DIR, 'modele-ai-camera/detecteur_main.pt')

print("=" * 70)
print("ANALYSE DU MODÈLE .PT ORIGINAL")
print("=" * 70)
print(f"Modèle: {DETECTOR_PT}")

try:
    model = YOLO(DETECTOR_PT)
    
    print(f"\nModèle chargé: {model}")
    print(f"Task: {model.task}")
    print(f"Names: {model.names}")
    
    # Vérifier la taille d'entrée
    if hasattr(model, 'args'):
        print(f"\nArgs: {model.args}")
        if hasattr(model.args, 'imgsz'):
            print(f"Image size from args: {model.args.imgsz}")
    
    # Essayer d'inférer la taille depuis le modèle
    print(f"\nModel info:")
    print(model.info())
    
except Exception as e:
    print(f"Erreur: {e}")
    import traceback
    traceback.print_exc()
