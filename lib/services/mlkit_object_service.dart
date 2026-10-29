import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Service de détection IA utilisant Google ML Kit Object Detection + TFLite
/// 
/// Architecture:
/// - ML Kit Object Detection: Détection de mains (objets)
/// - TFLite: Classification des signes LST
/// 
/// Avantages:
/// - API officielle Google, stable et testée
/// - Fonctionne sur Android/iOS
/// - Pas besoin de modèles personnalisés pour la détection
class MLKitObjectService {
  static MLKitObjectService? _i;
  static MLKitObjectService get i => _i ??= MLKitObjectService._();
  MLKitObjectService._();

  ObjectDetector? _objectDetector;
  Interpreter? _classifier;
  List<String>? _labels;
  
  bool _ready = false;
  bool _busy = false;
  
  // Stabilisation temporelle
  final List<String> _predictionHistory = [];
  static const int _historySize = 5;
  
  // Configuration normalisation
  static const String _normalizationMode = 'imagenet';
  
  static const int cSize = 224;
  static const double cTh = 0.4;

  void Function(String label, double confidence, List<double>? bbox)? onResult;
  void Function(String error)? onError;

  bool get isReady => _ready;

  Future<void> initialize() async {
    if (kIsWeb) {
      onError?.call('IA non disponible sur Web');
      return;
    }
    
    try {
      print('[MLKit] Initialisation...');
      
      // 1. Configurer ML Kit Object Detector
      // Mode STREAM pour détection en temps réel
      final options = ObjectDetectorOptions(
        mode: DetectionMode.stream,
        classifyObjects: false,  // On utilise notre propre classifieur
        trackObjects: true,        // Tracking pour fluidité
        multipleObjects: true,     // Détecter plusieurs mains
      );
      
      _objectDetector = ObjectDetector(options: options);
      print('[MLKit] Object Detector créé');
      
      // 2. Charger le classifieur TFLite
      _classifier = await Interpreter.fromAsset(
        'assets/models/classifieur_signe_float32.tflite',
        options: InterpreterOptions()..threads = 2,
      );
      print('[MLKit] Classifieur TFLite chargé');
      
      // 3. Charger les labels
      final labelsData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsData
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      print('[MLKit] ${_labels!.length} labels chargés');
      
      _ready = true;
      print('[MLKit] ✅ Service prêt');
      
    } catch (e, st) {
      print('[MLKit] ❌ Erreur init: $e\n$st');
      onError?.call('Erreur: $e');
    }
  }

  Future<void> processCameraImage(CameraImage image) async {
    if (!_ready || _busy) return;
    _busy = true;
    
    try {
      // Convertir CameraImage en InputImage pour ML Kit
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _busy = false;
        return;
      }
      
      // Détection des objets (mains)
      final objects = await _objectDetector!.processImage(inputImage);
      
      // Filtrer pour ne garder que les objets qui ressemblent à des mains
      // (ML Kit détecte les mains comme des objets génériques)
      final hands = objects.where((obj) {
        // Un objet qui pourrait être une main:
        // - Forme approximativement carrée ou rectangulaire verticale
        // - Taille raisonnable (pas trop petit, pas trop grand)
        final bbox = obj.boundingBox;
        final aspectRatio = bbox.width / bbox.height;
        final area = bbox.width * bbox.height;
        
        // Main = aspect ratio 0.5-2.0, area 5%-50% de l'image
        return aspectRatio >= 0.5 && 
               aspectRatio <= 2.0 && 
               area >= 0.05 && 
               area <= 0.5;
      }).toList();
      
      if (hands.isEmpty) {
        onResult?.call('?', 0.0, null);
        _busy = false;
        return;
      }
      
      // Prendre le plus grand objet (probablement la main)
      final bestHand = hands.reduce((a, b) => 
        (a.boundingBox.width * a.boundingBox.height) > 
        (b.boundingBox.width * b.boundingBox.height) ? a : b);
      
      // Convertir l'image pour cropping
      final rgbImage = _yuvToImage(image);
      if (rgbImage == null) {
        _busy = false;
        return;
      }
      
      // Crop la main
      final bbox = bestHand.boundingBox;
      final cropped = _cropWithPadding(rgbImage, bbox);
      if (cropped == null) {
        _busy = false;
        return;
      }
      
      // Classification
      final result = await _classify(cropped);
      
      // Retourner résultat
      final normalizedBbox = [
        bbox.left,
        bbox.top,
        bbox.right,
        bbox.bottom,
      ];
      
      onResult?.call(result['label'], result['confidence'], normalizedBbox);
      
    } catch (e) {
      print('[MLKit] Process error: $e');
    } finally {
      _busy = false;
    }
  }

  Future<void> processImage(img.Image image) async {
    if (!_ready || _busy) return;
    _busy = true;
    
    try {
      print('[MLKit] Traitement image ${image.width}x${image.height}');
      
      // Convertir en InputImage
      final inputImage = _convertImage(image);
      if (inputImage == null) {
        _busy = false;
        return;
      }
      
      // Détection
      final objects = await _objectDetector!.processImage(inputImage);
      
      // Filtrer les mains
      final hands = objects.where((obj) {
        final bbox = obj.boundingBox;
        final aspectRatio = bbox.width / bbox.height;
        final area = bbox.width * bbox.height;
        return aspectRatio >= 0.5 && aspectRatio <= 2.0 && 
               area >= 0.05 && area <= 0.5;
      }).toList();
      
      if (hands.isEmpty) {
        print('[MLKit] Aucune main détectée');
        onResult?.call('?', 0.0, null);
        _busy = false;
        return;
      }
      
      print('[MLKit] ${hands.length} objet(s) détecté(s)');
      
      // Meilleure main
      final bestHand = hands.reduce((a, b) => 
        (a.boundingBox.width * a.boundingBox.height) > 
        (b.boundingBox.width * b.boundingBox.height) ? a : b);
      
      final bbox = bestHand.boundingBox;
      final cropped = _cropWithPadding(image, bbox);
      if (cropped == null) {
        _busy = false;
        return;
      }
      
      final result = await _classify(cropped);
      
      final normalizedBbox = [
        bbox.left,
        bbox.top,
        bbox.right,
        bbox.bottom,
      ];
      
      print('[MLKit] Classification: ${result['label']} (${result['confidence'].toStringAsFixed(2)})');
      onResult?.call(result['label'], result['confidence'], normalizedBbox);
      
    } catch (e) {
      print('[MLKit] Image process error: $e');
    } finally {
      _busy = false;
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final writeBuffer = WriteBuffer();
      for (final plane in image.planes) {
        writeBuffer.putUint8List(plane.bytes);
      }
      final bytes = writeBuffer.done().buffer.asUint8List();
      
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  InputImage? _convertImage(img.Image image) {
    try {
      // Convertir en bytes BGRA pour ML Kit
      final bytes = _imageToBgraBytes(image);
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: image.width * 4,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// Convertit img.Image en bytes BGRA pour ML Kit
  Uint8List _imageToBgraBytes(img.Image image) {
    final bytes = Uint8List(image.width * image.height * 4);
    int idx = 0;
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        bytes[idx++] = img.getBlue(pixel);   // B
        bytes[idx++] = img.getGreen(pixel);  // G
        bytes[idx++] = img.getRed(pixel);    // R
        bytes[idx++] = 255;                  // A (opaque)
      }
    }
    
    return bytes;
  }

  img.Image? _yuvToImage(CameraImage c) {
    try {
      final w = c.width, h = c.height;
      final y = c.planes[0], u = c.planes[1], v = c.planes[2];
      final ys = y.bytesPerRow, us = u.bytesPerRow, up = u.bytesPerPixel!;
      final out = img.Image(w, h);
      
      for (int ry = 0; ry < h; ry++) {
        for (int rx = 0; rx < w; rx++) {
          final yi = ry * ys + rx;
          final uvi = (ry ~/ 2) * us + (rx ~/ 2) * up;
          int r = (y.bytes[yi] + 1.402 * (v.bytes[uvi] - 128)).round();
          int g = (y.bytes[yi] - 0.344136 * (u.bytes[uvi] - 128) - 0.714136 * (v.bytes[uvi] - 128)).round();
          int b = (y.bytes[yi] + 1.772 * (u.bytes[uvi] - 128)).round();
          out.setPixelRgba(rx, ry, r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255), 255);
        }
      }
      return out;
    } catch (e) {
      return null;
    }
  }

  img.Image? _cropWithPadding(img.Image image, Rect bbox) {
    final x1 = (bbox.left * image.width).toInt();
    final y1 = (bbox.top * image.height).toInt();
    final x2 = (bbox.right * image.width).toInt();
    final y2 = (bbox.bottom * image.height).toInt();
    
    final w = x2 - x1;
    final h = y2 - y1;
    final side = (math.max(w, h) * 1.3).toInt();
    final cx = (x1 + x2) ~/ 2;
    final cy = (y1 + y2) ~/ 2;
    
    final fx1 = math.max(0, cx - side ~/ 2);
    final fy1 = math.max(0, cy - side ~/ 2);
    final fw = math.min(image.width - fx1, side);
    final fh = math.min(image.height - fy1, side);
    
    if (fw <= 0 || fh <= 0) return null;
    
    return img.copyCrop(image, fx1, fy1, fw, fh);
  }

  /// Letterboxing: redimensionne en préservant l'aspect ratio avec padding noir
  img.Image _letterboxResize(img.Image image, int targetWidth, int targetHeight) {
    // 1. Calculer le ratio pour ne pas déformer l'image
    double ratioW = targetWidth / image.width;
    double ratioH = targetHeight / image.height;
    double ratio = ratioW < ratioH ? ratioW : ratioH;

    int newWidth = (image.width * ratio).toInt();
    int newHeight = (image.height * ratio).toInt();

    // 2. Redimensionner l'image originale proprement
    img.Image resized = img.copyResize(image, width: newWidth, height: newHeight, interpolation: img.Interpolation.cubic);

    // 3. Créer une image de fond noire (le "canvas" de 224x224)
    img.Image canvas = img.Image(targetWidth, targetHeight);
    img.fill(canvas, img.getColor(0, 0, 0)); // Fond noir

    // 4. Centrer l'image redimensionnée sur le canvas noir
    int xOffset = (targetWidth - newWidth) ~/ 2;
    int yOffset = (targetHeight - newHeight) ~/ 2;

    img.copyInto(canvas, resized, dstX: xOffset, dstY: yOffset);

    return canvas;
  }

  Future<Map<String, dynamic>> _classify(img.Image hand) async {
    // Letterboxing au lieu de copyResize direct
    final rs = _letterboxResize(hand, cSize, cSize);
    
    final inp = _imageToTensor(rs);
    final out = List.generate(1, (_) => List.filled(_labels!.length, 0.0));
    
    _classifier!.run(inp, out);
    
    final scores = out[0];
    int bi = 0;
    double bc = scores[0];
    
    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > bc) {
        bc = scores[i];
        bi = i;
      }
    }
    
    // Stabilisation temporelle
    final stabilizedLabel = _stabilizePrediction(_labels![bi]);
    
    return {'label': stabilizedLabel, 'confidence': bc};
  }

  /// Stabilisation temporelle par vote majoritaire
  String _stabilizePrediction(String currentPrediction) {
    // Ajouter la nouvelle prédiction à l'historique
    _predictionHistory.add(currentPrediction);

    // Garder seulement les X dernières frames (ex: 5)
    if (_predictionHistory.length > _historySize) {
      _predictionHistory.removeAt(0);
    }

    // Compter les occurrences de chaque mot
    Map<String, int> counts = {};
    for (var label in _predictionHistory) {
      counts[label] = (counts[label] ?? 0) + 1;
    }

    // Trouver le gagnant (celui qui a le plus de votes)
    var sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.first.key;
  }

  List _imageToTensor(img.Image im) {
    // Création du tenseur vide [1, 224, 224, 3]
    var input = List.generate(1, (_) => List.generate(224, (_) => List.generate(224, (_) => List<double>.filled(3, 0.0))));

    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        var pixel = im.getPixel(x, y);
        double r = img.getRed(pixel).toDouble();
        double g = img.getGreen(pixel).toDouble();
        double b = img.getBlue(pixel).toDouble();

        switch (_normalizationMode) {
          case 'zero_one': // Standard (0.0 à 1.0)
            input[0][y][x][0] = r / 255.0;
            input[0][y][x][1] = g / 255.0;
            input[0][y][x][2] = b / 255.0;
            break;
          case 'minus_one_one': // TensorFlow ( -1.0 à 1.0)
            input[0][y][x][0] = (r / 127.5) - 1.0;
            input[0][y][x][1] = (g / 127.5) - 1.0;
            input[0][y][x][2] = (b / 127.5) - 1.0;
            break;
          case 'imagenet': // ImageNet (Mean/Std)
            input[0][y][x][0] = (r / 255.0 - 0.485) / 0.229;
            input[0][y][x][1] = (g / 255.0 - 0.456) / 0.224;
            input[0][y][x][2] = (b / 255.0 - 0.406) / 0.225;
            break;
          default:
            input[0][y][x][0] = r / 255.0;
            input[0][y][x][1] = g / 255.0;
            input[0][y][x][2] = b / 255.0;
        }
      }
    }
    return input;
  }

  void dispose() {
    _objectDetector?.close();
    _classifier?.close();
    _ready = false;
  }
}
