import 'dart:math' as math;
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hand_detection/hand_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Service de détection IA utilisant MediaPipe Hands + TFLite
/// 
/// Architecture:
/// - hand_detection (MediaPipe): Détection précise des mains (21 landmarks)
/// - TFLite: Classification des signes LST
/// 
/// Avantages:
/// - API simple et stable
/// - Détection spécialisée des mains (pas objets génériques)
/// - 21 landmarks pour précision maximale
/// - Fonctionne offline
/// Labels fixes des 26 signes LST (ordre exact du dataset d'entraînement)
const List<String> tslLabels = [
  "armee",      // 0
  "carta",      // 1
  "centre",     // 2
  "dance",      // 3
  "dar",        // 4
  "directeur",  // 5
  "entendant",  // 6
  "entikhabet", // 7
  "esm",        // 8
  "faux",       // 9
  "handicap",   // 10
  "help",       // 11
  "jadda",      // 12
  "kahwa",      // 13
  "labes",      // 14
  "maman",      // 15
  "objectif",   // 16
  "officiel",   // 17
  "psychologie",// 18
  "septembre",  // 19
  "soeur",      // 20
  "sponsor",    // 21
  "taxi",       // 22
  "travailler", // 23
  "universite", // 24
  "wileya",     // 25
];

class HandDetectionService {
  static HandDetectionService? _i;
  static HandDetectionService get i => _i ??= HandDetectionService._();
  HandDetectionService._();

  HandDetector? _handDetector;
  Interpreter? _classifier;
  List<String>? _labels;
  
  bool _ready = false;
  bool _busy = false;
  int _frameSkip = 0;

  // Stabilisation temporelle
  final List<String> _predictionHistory = [];
  static const int _historySize = 5; // Vote sur 5 frames

  // Configuration normalisation
  // Options: 'zero_one', 'imagenet', 'minus_one_one'
  // NOTE: Ultralytics par défaut utilise normalization '0-1' (divise par 255)
  // 'imagenet' (Mean/Std) peut donner de mauvais résultats si le modèle n'a pas été entraîné ainsi
  static const String _normalizationMode = 'zero_one'; // Utilise la normalisation par défaut d'Ultralytics

  static const int cSize = 224;
  static const double cTh = 0.4;
  static const int _skipEvery = 5; // Traiter 1 frame sur 5

  void Function(String label, double confidence, List<double>? bbox)? onResult;
  void Function(String error)? onError;

  bool get isReady => _ready;
  bool get busy => _busy;

  Future<void> initialize() async {
    if (kIsWeb) {
      onError?.call('IA non disponible sur Web');
      return;
    }
    
    try {
      print('[HandDetection] Initialisation...');
      
      // 1. Créer le détecteur de mains MediaPipe
      _handDetector = await HandDetector.create();
      print('[HandDetection] MediaPipe HandDetector créé');
      
      // 2. Charger le classifieur TFLite
      _classifier = await Interpreter.fromAsset(
        'assets/models/classifieur_signe_float32.tflite',
        options: InterpreterOptions()..threads = 2,
      );
      print('[HandDetection] Classifieur TFLite chargé');
      
      // Debug: shapes et types des tensors
      final inTensor = _classifier!.getInputTensor(0);
      final outTensor = _classifier!.getOutputTensor(0);
      print('[HandDetection] TFLite input shape=${inTensor.shape}, type=${inTensor.type}');
      print('[HandDetection] TFLite output shape=${outTensor.shape}, type=${outTensor.type}');
      
      // 3. Charger les labels (fallback sur tslLabels si fichier incorrect)
      try {
        final labelsData = await rootBundle.loadString('assets/models/labels.txt');
        _labels = labelsData
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();
      } catch (e) {
        print('[HandDetection] ⚠️ labels.txt introuvable, fallback sur tslLabels');
        _labels = List.from(tslLabels);
      }
      if (_labels!.length != tslLabels.length) {
        print('[HandDetection] ⚠️ labels mismatch: ${_labels!.length} != ${tslLabels.length}, fallback tslLabels');
        _labels = List.from(tslLabels);
      }
      print('[HandDetection] ${_labels!.length} labels chargés: ${_labels!.take(5).join(", ")}...');
      
      _ready = true;
      print('[HandDetection] ✅ Service prêt');
      
    } catch (e, st) {
      print('[HandDetection] ❌ Erreur init: $e\n$st');
      onError?.call('Erreur: $e');
    }
  }

  /// Traite un img.Image statique (pour photos) - convertit en JPEG puis détecte
  Future<void> processImage(img.Image image) async {
    if (!_ready || _busy) return;
    _busy = true;

    try {
      print('[HandDetection] Traitement image statique ${image.width}x${image.height}');

      // Convertir img.Image en bytes JPEG
      final jpegBytes = _imageToJpegBytes(image);
      if (jpegBytes == null) {
        _busy = false;
        return;
      }

      // Détection des mains avec MediaPipe
      final hands = await _handDetector!.detect(jpegBytes);

      if (hands.isEmpty) {
        print('[HandDetection] Aucune main détectée');
        onResult?.call('?', 0.0, null);
        _busy = false;
        return;
      }

      print('[HandDetection] ${hands.length} main(s) détectée(s)');

      final bestHand = hands.reduce((a, b) {
        final areaA = a.boundingBox.width * a.boundingBox.height;
        final areaB = b.boundingBox.width * b.boundingBox.height;
        return areaA > areaB ? a : b;
      });

      final bbox = bestHand.boundingBox;

      // Crop la main avec padding
      final cropped = _cropHand(image, bbox);
      if (cropped == null || cropped.width == 0 || cropped.height == 0) {
        print('[HandDetection] ⚠️ Crop invalide, skipped');
        _busy = false;
        return;
      }

      // Classification
      final result = await _classify(cropped);

      // Seuil de confiance minimum ajusté à 0.5 pour tester imagenet
      const minConfidence = 0.5;
      if (result['confidence'] < minConfidence) {
        print('[HandDetection] Confiance trop faible (${result['confidence'].toStringAsFixed(2)} < $minConfidence), ignoré');
        onResult?.call('?', 0.0, null);
        _busy = false;
        return;
      }

      final normalizedBbox = [
        bbox.left,
        bbox.top,
        bbox.right,
        bbox.bottom,
      ];

      print('[HandDetection] Classification: ${result['label']} (${result['confidence'].toStringAsFixed(2)})');
      onResult?.call(result['label'], result['confidence'], normalizedBbox);

    } catch (e, st) {
      print('[HandDetection] Erreur: $e\n$st');
    } finally {
      _busy = false;
    }
  }

  /// Convertit img.Image en bytes JPEG
  Uint8List? _imageToJpegBytes(img.Image image) {
    try {
      final encoded = img.encodeJpg(image, quality: 90);
      return Uint8List.fromList(encoded);
    } catch (e) {
      print('[HandDetection] Erreur conversion JPEG: $e');
      return null;
    }
  }

  /// Traite un CameraImage directement avec detectFromCameraImage (natif, isolate)
  /// Convertit en img.Image UNIQUEMENT si une main est détectée (économie CPU)
  Future<void> processCameraImage(CameraImage cameraImage) async {
    if (!_ready || _busy) return;
    _frameSkip++;
    if (_frameSkip % _skipEvery != 0) {
      _busy = false;
      return;
    }
    _busy = true;

    try {
      print('[HandDetection] Traitement CameraImage ${cameraImage.width}x${cameraImage.height} (frame $_frameSkip)');

      // 1. Détection native rapide (YUV420 géré dans l'isolate natif, pas de blocage UI)
      final hands = await _handDetector!.detectFromCameraImage(
        cameraImage,
        maxDim: 640,
      );

      if (hands.isEmpty) {
        print('[HandDetection] Aucune main détectée');
        onResult?.call('?', 0.0, null);
        _busy = false;
        return;
      }

      print('[HandDetection] ${hands.length} main(s) détectée(s)');

      // 2. Convertir CameraImage → img.Image UNIQUEMENT si main détectée
      final image = _convertCameraImage(cameraImage);
      if (image == null) {
        print('[HandDetection] Erreur conversion CameraImage → img.Image');
        _busy = false;
        return;
      }

      // Prendre la main avec la plus grande bounding box
      final bestHand = hands.reduce((a, b) {
        final areaA = a.boundingBox.width * a.boundingBox.height;
        final areaB = b.boundingBox.width * b.boundingBox.height;
        return areaA > areaB ? a : b;
      });

      final bbox = bestHand.boundingBox;

      // Crop la main avec padding
      final cropped = _cropHand(image, bbox);
      if (cropped == null || cropped.width == 0 || cropped.height == 0) {
        print('[HandDetection] ⚠️ Crop invalide, skipped');
        _busy = false;
        return;
      }
      print('[HandDetection] Crop OK: ${cropped.width}x${cropped.height}');

      // Classification
      final result = await _classify(cropped);

      // Seuil de confiance minimum ajusté à 0.5 pour tester imagenet
      const minConfidence = 0.5;
      if (result['confidence'] < minConfidence) {
        print('[HandDetection] Confiance trop faible (${result['confidence'].toStringAsFixed(2)} < $minConfidence), ignoré');
        onResult?.call('?', 0.0, null);
        _busy = false;
        return;
      }

      // Retourner résultat avec bbox normalisée
      final normalizedBbox = [
        bbox.left,
        bbox.top,
        bbox.right,
        bbox.bottom,
      ];

      print('[HandDetection] Classification: ${result['label']} (${result['confidence'].toStringAsFixed(2)})');
      onResult?.call(result['label'], result['confidence'], normalizedBbox);

    } catch (e, st) {
      print('[HandDetection] Erreur: $e\n$st');
    } finally {
      _busy = false;
    }
  }

  /// Crop la main avec padding de 5% (pour que la main occupe plus l'image)
  /// NOTE: MediaPipe BoundingBox est en PIXELS ABSOLUS (pas normalisé 0-1)
  img.Image? _cropHand(img.Image image, BoundingBox bbox) {
    print('[HandDetection] _cropHand: bbox=[${bbox.left}, ${bbox.top}, ${bbox.right}, ${bbox.bottom}] image=${image.width}x${image.height}');

    // MediaPipe retourne déjà des coordonnées en pixels
    final x1 = bbox.left.toInt();
    final y1 = bbox.top.toInt();
    final x2 = bbox.right.toInt();
    final y2 = bbox.bottom.toInt();

    print('[HandDetection] _cropHand: pixels=[x1=$x1, y1=$y1, x2=$x2, y2=$y2]');

    final w = x2 - x1;
    final h = y2 - y1;

    if (w <= 0 || h <= 0) {
      print('[HandDetection] _cropHand: bbox invalide (w=$w, h=$h)');
      return null;
    }

    // Padding réduit à 5% (1.05) pour que la main occupe plus l'image
    final side = (math.max(w, h) * 1.05).toInt();
    final cx = (x1 + x2) ~/ 2;
    final cy = (y1 + y2) ~/ 2;

    final fx1 = math.max(0, cx - side ~/ 2);
    final fy1 = math.max(0, cy - side ~/ 2);
    final fw = math.min(image.width - fx1, side);
    final fh = math.min(image.height - fy1, side);

    print('[HandDetection] _cropHand: crop=[fx1=$fx1, fy1=$fy1, fw=$fw, fh=$fh]');

    if (fw <= 0 || fh <= 0) {
      print('[HandDetection] _cropHand: crop invalide (fw=$fw, fh=$fh)');
      return null;
    }

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

  /// Amélioration du contraste (optionnel, pour réduire l'impact des reflets)
  /// À activer dans _classify si nécessaire
  img.Image _enhanceContrast(img.Image image) {
    final enhanced = img.Image(image.width, image.height);
    const double alpha = 1.5; // Facteur de contraste (1.0 = pas de changement)
    const double beta = 0.0;   // Compensation de luminosité
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);
        final r = (img.getRed(p) * alpha + beta).clamp(0, 255).toInt();
        final g = (img.getGreen(p) * alpha + beta).clamp(0, 255).toInt();
        final b = (img.getBlue(p) * alpha + beta).clamp(0, 255).toInt();
        enhanced.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    return enhanced;
  }

  /// Classification avec TFLite (format 4D [1,224,224,3] pour couche PAD)
  Future<Map<String, dynamic>> _classify(img.Image hand) async {
    print('[HandDetection] _classify start, hand=${hand.width}x${hand.height}');
    
    // Optionnel: Amélioration du contraste pour réduire l'impact des reflets
    // final enhanced = _enhanceContrast(hand);
    
    // Letterboxing: préserver l'aspect ratio avec padding noir
    final rs = _letterboxResize(hand, cSize, cSize);
    print('[HandDetection] letterbox done, rs=${rs.width}x${rs.height}');

    final inp = _imageToTensor4D(rs);
    print('[HandDetection] _imageToTensor4D done');

    final out = List.generate(1, (_) => List.filled(_labels!.length, 0.0));
    print('[HandDetection] output buffer ready: [1, ${_labels!.length}]');

    // Exécuter TFLite sur le main thread avec yield pour éviter ANR
    try {
      await Future.delayed(Duration.zero); // yield au UI thread
      _classifier!.run(inp, out);
      print('[HandDetection] TFLite run completed');
    } catch (e, st) {
      print('[HandDetection] ❌ TFLite run FAILED: $e\n$st');
      return {'label': 'Erreur TFLite', 'confidence': 0.0};
    }

    final scores = out[0];
    int bi = 0;
    double bc = scores[0];

    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > bc) {
        bc = scores[i];
        bi = i;
      }
    }

    // Log top 3 pour diagnostic
    final sorted = List<MapEntry<int, double>>.generate(scores.length, (i) => MapEntry(i, scores[i]))
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = sorted.take(3).map((e) => '${_labels![e.key]}=${e.value.toStringAsFixed(3)}').join(', ');
    print('[HandDetection] Top3: $top3');

    print('[HandDetection] _classify end => label=${_labels![bi]}, conf=$bc');
    
    // Stabilisation temporelle (uniquement si confiance suffisante)
    String stabilizedLabel;
    if (bc >= 0.5) {
      stabilizedLabel = _stabilizePrediction(_labels![bi]);
    } else {
      // Si confiance faible, ne pas polluer l'historique
      stabilizedLabel = _labels![bi];
      print('[HandDetection] Confiance faible ($bc), stabilisation ignorée');
    }
    
    return {'label': stabilizedLabel, 'confidence': bc};
  }

  /// Stabilisation temporelle par vote majoritaire sur N frames
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

    final result = sortedEntries.first.key;
    print('[HandDetection] Stabilized: $result (count=${sortedEntries.first.value}/${_predictionHistory.length})');
    return result;
  }

  /// Convertit img.Image en tenseur 4D [1][224][224][3] en float32
  /// Supporte plusieurs modes de normalisation
  List _imageToTensor4D(img.Image im) {
    print('[HandDetection] _imageToTensor4D start (mode=$_normalizationMode)');
    
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
    print('[HandDetection] _imageToTensor4D done');
    return input;
  }

  /// Méthode proc pour compatibilité avec les pages existantes
  /// Appelle processCameraImage qui utilise detectFromCameraImage natif
  Future<void> proc(CameraImage cameraImage) async {
    await processCameraImage(cameraImage);
  }
  
  /// Convertit CameraImage (format natif caméra) en img.Image
  img.Image? _convertCameraImage(CameraImage cameraImage) {
    try {
      final width = cameraImage.width;
      final height = cameraImage.height;
      
      // Pour format YUV420 (standard Android)
      if (cameraImage.format.group == ImageFormatGroup.yuv420) {
        final yPlane = cameraImage.planes[0].bytes;
        final uPlane = cameraImage.planes[1].bytes;
        final vPlane = cameraImage.planes[2].bytes;
        
        return _convertYUV420ToImage(yPlane, uPlane, vPlane, width, height);
      }
      
      // Pour format BGRA8888 (standard iOS)
      if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
        final bytes = cameraImage.planes[0].bytes;
        return img.Image.fromBytes(width, height, bytes);
      }
      
      print('[HandDetection] Format non supporté: ${cameraImage.format.group}');
      return null;
    } catch (e) {
      print('[HandDetection] Erreur conversion: $e');
      return null;
    }
  }
  
  /// Conversion YUV420 → RGB
  img.Image _convertYUV420ToImage(Uint8List yData, Uint8List uData, Uint8List vData, int width, int height) {
    final image = img.Image(width, height);
    
    final yRowStride = width;
    final uvRowStride = (width + 1) ~/ 2;
    final uvPixelStride = 2;
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * yRowStride + x;
        final uvRow = y ~/ 2;
        final uvCol = x ~/ 2;
        final uvIndex = uvRow * uvRowStride + uvCol * uvPixelStride;
        
        final yValue = yData[yIndex];
        final uValue = uData[uvIndex];
        final vValue = vData[uvIndex];
        
        // Conversion YUV → RGB
        final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toInt();
        final g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128)).clamp(0, 255).toInt();
        final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();
        
        image.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    
    return image;
  }

  void dispose() {
    _handDetector?.dispose();
    _classifier?.close();
    _ready = false;
  }
}
