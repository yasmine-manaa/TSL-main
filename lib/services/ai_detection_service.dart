import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class AIDetectionService {
  static AIDetectionService? _instance;
  static AIDetectionService get instance => _instance ??= AIDetectionService._();
  
  AIDetectionService._();

  Interpreter? _interpreterDet;
  Interpreter? _interpreterCls;
  List<String>? _labels;
  
  bool _isInitialized = false;
  bool _isDetecting = false;

  // Callbacks pour les résultats
  Function(String letter, double confidence)? onDetectionResult;
  Function(String error)? onError;

  // Initialisation des modèles
  Future<void> initializeModels() async {
    try {
      print('AI Detection: Initialisation des modèles...');
      
      // 1. Charger les deux modèles en mémoire
      _interpreterDet = await Interpreter.fromAsset('assets/models/detecteur_main_float32.tflite');
      _interpreterCls = await Interpreter.fromAsset('assets/models/classifieur_signe_float32.tflite');
      
      // 2. Charger les labels
      final labelsData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsData.split('\n').map((label) => label.trim()).where((label) => label.isNotEmpty).toList();
      
      _isInitialized = true;
      print('AI Detection: Modèles initialisés avec succès');
      print('AI Detection: Labels chargés: ${_labels?.length ?? 0}');
      
    } catch (e) {
      print('AI Detection: Erreur lors de l\'initialisation: $e');
      onError?.call('Erreur lors du chargement des modèles: $e');
    }
  }

  // Vérifier si les modèles sont initialisés
  bool get isInitialized => _isInitialized;

  // Traitement d'une frame de caméra
  Future<void> processCameraFrame(CameraImage cameraImage) async {
    if (!_isInitialized || _isDetecting) return;
    
    _isDetecting = true;
    
    try {
      // A. Détection : Envoyer l'image complète à interpreterDet
      final detectionResults = await _runDetection(cameraImage);
      
      if (detectionResults.isNotEmpty) {
        // B. Logique d'englobement : Calculer fx1, fy1, fx2, fy2 comme en Python
        final cropRect = _calculateGlobalRect(detectionResults);
        
        // C. Crop : Découper l'image
        final handCrop = _cropImage(cameraImage, cropRect);
        
        if (handCrop != null) {
          // D. Classification : Envoyer le crop à interpreterCls
          final classificationResult = await _runClassification(handCrop);
          
          // E. Affichage : Mettre à jour l'interface avec la lettre détectée
          if (classificationResult['label'] != null && classificationResult['confidence'] != null) {
            onDetectionResult?.call(
              classificationResult['label'],
              classificationResult['confidence'],
            );
          }
        }
      }
    } catch (e) {
      print('AI Detection: Erreur lors du traitement de la frame: $e');
      onError?.call('Erreur de traitement: $e');
    } finally {
      _isDetecting = false;
    }
  }

  // A. Détection de la main
  Future<List<Map<String, dynamic>>> _runDetection(CameraImage cameraImage) async {
    try {
      // Convertir CameraImage en format compatible
      final image = _convertCameraImageToImage(cameraImage);
      
      // Redimensionner pour le modèle de détection (typiquement 320x320)
      final resizedImage = img.copyResize(image, width: 320, height: 320);
      
      // Normaliser les pixels [0, 255] -> [0, 1]
      final input = _imageToTensor(resizedImage);
      
      // Préparer la sortie
      final output = List.filled(1 * 7 * 7 * 2, 0.0).reshape([1, 7, 7, 2]);
      
      // Exécuter l'inférence
      _interpreterDet!.run(input, output);
      
      // Traiter les résultats de détection
      return _processDetectionOutput(output);
      
    } catch (e) {
      print('AI Detection: Erreur de détection: $e');
      return [];
    }
  }

  // B. Calcul du rectangle englobant global
  Map<String, int> _calculateGlobalRect(List<Map<String, dynamic>> detectionResults) {
    if (detectionResults.isEmpty) {
      return {'x': 0, 'y': 0, 'width': 100, 'height': 100};
    }
    
    int minX = 999999;
    int minY = 999999;
    int maxX = 0;
    int maxY = 0;
    
    for (final detection in detectionResults) {
      final x = detection['x'] as int;
      final y = detection['y'] as int;
      final w = detection['width'] as int;
      final h = detection['height'] as int;
      
      minX = (x < minX) ? x : minX;
      minY = (y < minY) ? y : minY;
      maxX = (x + w > maxX) ? x + w : maxX;
      maxY = (y + h > maxY) ? y + h : maxY;
    }
    
    // Ajouter une marge de 10%
    final marginX = ((maxX - minX) * 0.1).round();
    final marginY = ((maxY - minY) * 0.1).round();
    
    return {
      'x': (minX - marginX).clamp(0, 999999),
      'y': (minY - marginY).clamp(0, 999999),
      'width': (maxX - minX + 2 * marginX).clamp(10, 999999),
      'height': (maxY - minY + 2 * marginY).clamp(10, 999999),
    };
  }

  // C. Découpage de l'image
  img.Image? _cropImage(CameraImage cameraImage, Map<String, int> cropRect) {
    try {
      final image = _convertCameraImageToImage(cameraImage);
      
      final x = cropRect['x']!;
      final y = cropRect['y']!;
      final width = cropRect['width']!;
      final height = cropRect['height']!;
      
      // S'assurer que le rectangle est dans les limites de l'image
      final clampedX = x.clamp(0, image.width - 1);
      final clampedY = y.clamp(0, image.height - 1);
      final clampedWidth = width.clamp(1, image.width - clampedX);
      final clampedHeight = height.clamp(1, image.height - clampedY);
      
      return img.copyCrop(image, x: clampedX, y: clampedY, width: clampedWidth, height: clampedHeight);
    } catch (e) {
      print('AI Detection: Erreur lors du crop: $e');
      return null;
    }
  }

  // D. Classification du signe
  Future<Map<String, dynamic>> _runClassification(img.Image croppedImage) async {
    try {
      // Redimensionner pour le modèle de classification (typiquement 224x224)
      final resizedImage = img.copyResize(croppedImage, width: 224, height: 224);
      
      // Normaliser les pixels
      final input = _imageToTensor(resizedImage);
      
      // Préparer la sortie (nombre de classes)
      final numClasses = _labels?.length ?? 36; // Par défaut 36 classes (A-Z + 0-9)
      final output = List.filled(numClasses, 0.0).reshape([1, numClasses]);
      
      // Exécuter l'inférence
      _interpreterCls!.run(input, output);
      
      // Traiter les résultats de classification
      return _processClassificationOutput(output);
      
    } catch (e) {
      print('AI Detection: Erreur de classification: $e');
      return {'label': '?', 'confidence': 0.0};
    }
  }

  // Utilitaires de conversion et traitement
  img.Image _convertCameraImageToImage(CameraImage cameraImage) {
    // Convertir CameraImage en format img.Image
    final width = cameraImage.width;
    final height = cameraImage.height;
    
    final image = img.Image(width, height);
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixelIndex = y * width + x;
        
        if (cameraImage.format.group == ImageFormatGroup.yuv420) {
          // Format YUV420
          final yValue = cameraImage.planes[0].bytes[pixelIndex];
          image.setPixel(x, y, img.ColorRgb8(yValue, yValue, yValue));
        } else {
          // Format RGB ou autre
          final pixelOffset = pixelIndex * 3;
          if (pixelOffset + 2 < cameraImage.planes[0].bytes.length) {
            final r = cameraImage.planes[0].bytes[pixelOffset];
            final g = cameraImage.planes[0].bytes[pixelOffset + 1];
            final b = cameraImage.planes[0].bytes[pixelOffset + 2];
            image.setPixel(x, y, img.ColorRgb8(r, g, b));
          }
        }
      }
    }
    
    return image;
  }

  List<List<List<List<double>>>> _imageToTensor(img.Image image) {
    final tensor = List.generate(
      1,
      (i) => List.generate(
        image.height,
        (y) => List.generate(
          image.width,
          (x) {
            final pixel = image.getPixel(x, y);
            return [
              pixel.r / 255.0,  // Normalisation [0, 255] -> [0, 1]
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );
    
    return tensor;
  }

  List<Map<String, dynamic>> _processDetectionOutput(List<List<List<List<double>>>> output) {
    final results = <Map<String, dynamic>>[];
    
    // Parcourir la grille de détection (7x7)
    for (int y = 0; y < 7; y++) {
      for (int x = 0; x < 7; x++) {
        final confidence = output[0][y][x][0]; // Score de confiance
        final classScore = output[0][y][x][1]; // Score de classe
        
        if (confidence > 0.5) { // Seuil de confiance
          // Convertir les coordonnées de la grille en coordonnées d'image
          final imageX = (x * 320 / 7).round();
          final imageY = (y * 320 / 7).round();
          final width = (320 / 7).round();
          final height = (320 / 7).round();
          
          results.add({
            'x': imageX,
            'y': imageY,
            'width': width,
            'height': height,
            'confidence': confidence,
            'class': classScore > 0.5 ? 1 : 0, // 1 = main, 0 = fond
          });
        }
      }
    }
    
    return results;
  }

  Map<String, dynamic> _processClassificationOutput(List<List<double>> output) {
    final scores = output[0];
    
    // Trouver la classe avec le score le plus élevé
    double maxScore = 0.0;
    int maxIndex = 0;
    
    for (int i = 0; i < scores.length; i++) {
      if (scores[i] > maxScore) {
        maxScore = scores[i];
        maxIndex = i;
      }
    }
    
    // Obtenir le label correspondant
    final label = (_labels != null && maxIndex < _labels!.length) 
        ? _labels![maxIndex] 
        : '?';
    
    return {
      'label': label,
      'confidence': maxScore,
      'classIndex': maxIndex,
    };
  }

  // Libérer les ressources
  void dispose() {
    _interpreterDet?.close();
    _interpreterCls?.close();
    _interpreterDet = null;
    _interpreterCls = null;
    _labels = null;
    _isInitialized = false;
    _isDetecting = false;
  }
}
