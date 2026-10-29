// Test du package hand_landmarker
// Ce fichier est juste pour vérifier la syntaxe et les imports

import 'package:hand_landmarker/hand_landmarker.dart';
import 'package:camera/camera.dart';

void testHandLandmarker() {
  // Créer une instance du plugin
  final plugin = HandLandmarker();
  
  // Méthodes disponibles:
  // - initialize(): Future<void>
  // - detect(CameraImage image, int sensorOrientation): List<Hand>
  // - dispose(): void
  
  print('HandLandmarker methods:');
  print('- initialize(): Future<void>');
  print('- detect(CameraImage, int): List<Hand>');
  print('- dispose(): void');
  
  // Structure Hand:
  // - landmarks: List<Landmark> (21 points)
  // 
  // Structure Landmark:
  // - x: double (0.0-1.0)
  // - y: double (0.0-1.0)  
  // - z: double (profondeur)
  
  print('\nHand structure:');
  print('- List<Landmark> landmarks (21 points)');
  print('\nLandmark structure:');
  print('- x: double (normalized 0.0-1.0)');
  print('- y: double (normalized 0.0-1.0)');
  print('- z: double (depth)');
}
