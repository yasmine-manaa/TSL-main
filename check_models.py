import tensorflow as tf
import sys

print("Vérification des modèles TFLite...")
print("=" * 60)

try:
    # Charger le détecteur
    print("\n1. DÉTECTEUR: detecteur_main_float32.tflite")
    print("-" * 60)
    interpreter = tf.lite.Interpreter(model_path='assets/models/detecteur_main_float32.tflite')
    interpreter.allocate_tensors()

    print("Input details:")
    for inp in interpreter.get_input_details():
        print(f"  Shape: {inp['shape']}, Dtype: {inp['dtype']}")

    print("Output details:")
    for out in interpreter.get_output_details():
        print(f"  Shape: {out['shape']}, Dtype: {out['dtype']}")

except Exception as e:
    print(f"Erreur détecteur: {e}")

try:
    # Charger le classifieur  
    print("\n2. CLASSIFIEUR: classifieur_signe_float32.tflite")
    print("-" * 60)
    interpreter2 = tf.lite.Interpreter(model_path='assets/models/classifieur_signe_float32.tflite')
    interpreter2.allocate_tensors()

    print("Input details:")
    for inp in interpreter2.get_input_details():
        print(f"  Shape: {inp['shape']}, Dtype: {inp['dtype']}")

    print("Output details:")
    for out in interpreter2.get_output_details():
        print(f"  Shape: {out['shape']}, Dtype: {out['dtype']}")

except Exception as e:
    print(f"Erreur classifieur: {e}")

print("\n" + "=" * 60)
