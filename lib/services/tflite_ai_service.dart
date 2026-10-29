import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class TfliteAIService {
  static TfliteAIService? _i;
  static TfliteAIService get i => _i ??= TfliteAIService._();
  TfliteAIService._();

  Interpreter? det, cls;
  List<String>? labels;
  bool ready = false, busy = false;

  static const dSize = 384, cSize = 224;  // Détecteur: 384x384, Classifieur: 224x224
  static const cTh = 0.1;  // Seuil de confiance très bas pour tester

  void Function(String l, double c, List<double>? bbox)? onRes;
  void Function(String e)? onErr;

  bool get isInit => ready;

  Future<void> init() async {
    // TFLite ne fonctionne pas sur Web (pas de FFI)
    if (kIsWeb) {
      print('[TFLite] Skipped on Web - IA non disponible');
      ready = false;
      onErr?.call('IA non disponible sur Web');
      return;
    }
    try {
      print('[TFLite] Chargement du détecteur...');
      det = await Interpreter.fromAsset('assets/models/detecteur_main_float32.tflite', options: InterpreterOptions()..threads = 4);
      print('[TFLite] Détecteur chargé avec succès');
      
      print('[TFLite] Chargement du classifieur...');
      cls = await Interpreter.fromAsset('assets/models/classifieur_signe_float32.tflite', options: InterpreterOptions()..threads = 2);
      print('[TFLite] Classifieur chargé avec succès');
      
      print('[TFLite] Chargement des labels...');
      labels = (await rootBundle.loadString('assets/models/labels.txt')).split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      print('[TFLite] Labels chargés: ${labels!.length}');
      
      ready = true;
      print('[TFLite] ✅ Service TFLite prêt avec ${labels!.length} labels');
    } catch (e, st) {
      print('[TFLite] ❌ Init err: $e\n$st');
      onErr?.call('Erreur chargement: $e');
    }
  }

  Future<void> proc(CameraImage cam) async {
    if (!ready || busy) return;
    busy = true;
    try {
      final rgb = _yuv(cam);
      if (rgb == null) return;
      final boxes = await _det(rgb);
      if (boxes.isEmpty) return;
      final cr = _crop(boxes, rgb.width, rgb.height);
      final hand = img.copyCrop(rgb, cr['x1']!.toInt(), cr['y1']!.toInt(), cr['w']!.toInt(), cr['h']!.toInt());
      if (hand.width == 0 || hand.height == 0) return;
      final r = await _classify(hand);
      onRes?.call(r['l'] as String, r['c'] as double, null);
    } catch (e, st) {
      print('[TFLite] Frame err: $e\n$st');
    } finally {
      busy = false;
    }
  }

  /// Traite une image déjà décodée (depuis fichier JPEG)
  Future<void> procWithImage(img.Image image) async {
    if (!ready || busy) return;
    busy = true;
    try {
      print('[TFLite] Traitement image ${image.width}x${image.height}');
      final boxes = await _det(image);
      if (boxes.isEmpty) {
        print('[TFLite] Aucune main détectée');
        onRes?.call('?', 0.0, null);
        return;
      }
      print('[TFLite] ${boxes.length} boîtes détectées');
      
      // Prendre la boîte avec la meilleure confiance
      final bestBox = boxes.reduce((a, b) => (a['conf'] as double) > (b['conf'] as double) ? a : b);
      
      // Les boîtes sont déjà en pixels sur l'image originale
      // Convertir en coordonnées normalisées [x1, y1, x2, y2] pour l'affichage
      final bbox = [
        (bestBox['x'] as double) / image.width,
        (bestBox['y'] as double) / image.height,
        ((bestBox['x'] as double) + (bestBox['w'] as double)) / image.width,
        ((bestBox['y'] as double) + (bestBox['h'] as double)) / image.height,
      ];
      
      final cr = _crop(boxes, image.width, image.height);
      final hand = img.copyCrop(image, cr['x1']!.toInt(), cr['y1']!.toInt(), cr['w']!.toInt(), cr['h']!.toInt());
      if (hand.width == 0 || hand.height == 0) return;
      final r = await _classify(hand);
      print('[TFLite] Classification: ${r['l']} (${(r['c'] as double).toStringAsFixed(2)})');
      onRes?.call(r['l'] as String, r['c'] as double, bbox);
    } catch (e, st) {
      print('[TFLite] Image err: $e\n$st');
    } finally {
      busy = false;
    }
  }

  img.Image? _yuv(CameraImage c) {
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

  Future<List<Map<String, dynamic>>> _det(img.Image rgb) async {
    // Letterbox resize (comme Ultralytics) - padding avec couleur grise (114, 114, 114)
    final int maxDim = math.max(rgb.width, rgb.height);
    final double scale = dSize / maxDim;
    final int newW = (rgb.width * scale).round();
    final int newH = (rgb.height * scale).round();
    
    // Redimensionner
    final img.Image resized = img.copyResize(rgb, width: newW, height: newH, interpolation: img.Interpolation.cubic);
    
    // Créer l'image carrée avec padding gris
    final img.Image square = img.Image(dSize, dSize);
    final int padX = (dSize - newW) ~/ 2;
    final int padY = (dSize - newH) ~/ 2;
    
    // Remplir avec gris (114, 114, 114) comme Ultralytics
    for (int y = 0; y < dSize; y++) {
      for (int x = 0; x < dSize; x++) {
        square.setPixelRgba(x, y, 114, 114, 114, 255);
      }
    }
    
    // Copier l'image redimensionnée au centre
    for (int y = 0; y < newH; y++) {
      for (int x = 0; x < newW; x++) {
        square.setPixel(padX + x, padY + y, resized.getPixel(x, y));
      }
    }
    
    final inp = _tensor(square, dSize);
    
    print('[TFLite] Tensor shape: ${inp.length}x${inp[0].length}x${inp[0][0].length}x${inp[0][0][0].length}');
    
    final sh = det!.getOutputTensor(0).shape;
    print('[TFLite] Output tensor shape: $sh');
    
    // Allouer le tenseur de sortie avec la bonne forme
    dynamic out = List.generate(sh[0], (_) => List.generate(sh[1], (_) => List.generate(sh[2], (_) => 0.0)));
    det!.run(inp, out);
    return _parseYoloNMS(out, sh, scale, padX, padY, rgb.width, rgb.height);
  }

  /// Parse la sortie YOLOv8 [1, 7, num_detections] - CORRECTION OFFICIELLE ULTRALYTICS
  /// Format TFLite exporté par Ultralytics avec nms=True: [batch, attrs, detections]
  /// Après transpose(0, 2, 1): [batch, detections, attrs] = [1, 3024, 7]
  /// Les 7 attributs sont: [x_center, y_center, width, height, confidence, class_id, ?]
  List<Map<String, dynamic>> _parseYoloNMS(dynamic out, List<int> sh, double scale, int padX, int padY, int origW, int origH) {
    final boxes = <Map<String, dynamic>>[];
    if (sh.length == 3) {
      final o = out as List<List<List<double>>>;
      final numDetections = sh[2];  // 3024
      
      // Transpose(0, 2, 1): transformer [1, 7, 3024] en parcourant par detection d'abord
      for (int i = 0; i < numDetections; i++) {
        // Format après transpose: chaque detection a 7 attributs
        // [x_center, y_center, width, height, confidence, class_id, ?]
        final x_center = o[0][0][i];  // Coordonnées du centre (pas coin !)
        final y_center = o[0][1][i];
        final width = o[0][2][i];
        final height = o[0][3][i];
        final conf = o[0][4][i];
        
        if (conf < cTh) continue;
        if (width <= 0 || height <= 0) continue;
        
        // Convertir centre→coin (comme Ultralytics: x -= w/2, y -= h/2)
        double x1 = x_center - width / 2;
        double y1 = y_center - height / 2;
        double x2 = x_center + width / 2;
        double y2 = y_center + height / 2;
        
        // Les coordonnées TFLite avec nms=True sont NORMALISÉES (0-1), pas en pixels !
        // 1. Convertir 0-1 → pixels sur image 384x384: * dSize
        // 2. Soustraire padding
        // 3. Diviser par échelle → pixels sur image originale
        x1 = (x1 * dSize - padX) / scale;
        y1 = (y1 * dSize - padY) / scale;
        x2 = (x2 * dSize - padX) / scale;
        y2 = (y2 * dSize - padY) / scale;
        
        boxes.add({
          'x': x1,  // coin x sur image originale
          'y': y1,  // coin y sur image originale
          'w': x2 - x1,
          'h': y2 - y1,
          'conf': conf,
        });
      }
    }
    print('[TFLite] ${boxes.length} boxes détectées (threshold: $cTh)');
    return boxes;
  }

  Map<String, int> _crop(List<Map<String, dynamic>> b, int iw, int ih) {
    // Les boîtes sont déjà en pixels sur l'image originale (grâce à la reprojection)
    double x1 = 1e9, y1 = 1e9, x2 = -1e9, y2 = -1e9;
    for (final box in b) {
      x1 = math.min(x1, box['x'] as double);
      y1 = math.min(y1, box['y'] as double);
      x2 = math.max(x2, box['x'] + box['w']);
      y2 = math.max(y2, box['y'] + box['h']);
    }
    
    final s = (math.max(x2 - x1, y2 - y1) * 1.3).round();
    final cx = ((x1 + x2) / 2).round();
    final cy = ((y1 + y2) / 2).round();
    final fx1 = math.max(0, cx - s ~/ 2);
    final fy1 = math.max(0, cy - s ~/ 2);
    return {'x1': fx1, 'y1': fy1, 'w': math.min(iw, fx1 + s) - fx1, 'h': math.min(ih, fy1 + s) - fy1};
  }

  Future<Map<String, dynamic>> _classify(img.Image hand) async {
    final rs = img.copyResize(hand, width: cSize, height: cSize, interpolation: img.Interpolation.cubic);
    final inp = _tensor(rs, cSize);
    final out = List.generate(1, (_) => List.filled(labels!.length, 0.0));
    cls!.run(inp, out);
    final sc = (out as List<List<double>>)[0];
    int bi = 0;
    double bc = sc[0];
    for (int i = 1; i < sc.length; i++) if (sc[i] > bc) { bc = sc[i]; bi = i; }
    return {'l': labels![bi], 'c': bc};
  }

  List _tensor(img.Image im, int size) {
    final t = List.generate(1, (_) => List.generate(size, (y) => List.generate(size, (x) {
      final p = im.getPixel(x, y);
      return [img.getRed(p) / 255.0, img.getGreen(p) / 255.0, img.getBlue(p) / 255.0];
    })));
    return t;
  }

  void dispose() {
    det?.close();
    cls?.close();
    ready = false;
  }
}
