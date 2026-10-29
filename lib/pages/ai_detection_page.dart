import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;

import '../services/tflite_ai_service.dart';

const Color primaryRed = Color(0xFFE60012);
const Color bgGrey = Color(0xFFF5F5F5);

/// PAGE DE DÉTECTION IA - VERSION TESTÉE
/// Utilise takePicture() pour plus de stabilité
class AIDetectionPage extends StatefulWidget {
  const AIDetectionPage({super.key});

  @override
  State<AIDetectionPage> createState() => _AIDetectionPageState();
}

class _AIDetectionPageState extends State<AIDetectionPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isModelReady = false;
  bool _isDetecting = false;
  bool _isLiveMode = false;

  String _detectedSign = '?';
  double _confidence = 0.0;
  int _frameCount = 0;
  int _detectionCount = 0;
  String _statusMessage = 'Initialisation...';

  // Bounding box pour affichage
  List<double>? _bbox; // [x1, y1, x2, y2] en coordonnées normalisées (0-1)
  Size? _imageSize;

  final TfliteAIService _aiService = TfliteAIService.i;
  Timer? _detectionTimer;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    await _initAI();
    await _initCamera();
  }

  Future<bool> _ensureCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;

    final result = await Permission.camera.request();
    if (result.isGranted) return true;

    if (result.isPermanentlyDenied) {
      await openAppSettings();
    }
    return false;
  }

  Future<void> _initAI() async {
    try {
      print('[HandDetection] Initialisation...');
      await _aiService.init();
      
      if (_aiService.isInit) {
        // Configurer les callbacks
        _aiService.onRes = (String label, double conf, List<double>? bbox) {
          setState(() {
            _detectedSign = label;
            _confidence = conf;
            _bbox = bbox;
            if (bbox != null) _detectionCount++;
          });
        };
        
        _aiService.onErr = (String error) {
          print('[HandDetection] Error: $error');
        };
        
        setState(() {
          _isModelReady = true;
          _statusMessage = 'Modèle prêt - Détection active';
        });
        print('[HandDetection] Service prêt');
      } else {
        setState(() {
          _isModelReady = false;
          _statusMessage = 'Erreur: Modèle non disponible';
        });
        print('[HandDetection] Erreur init');
      }
    } catch (e) {
      print('[HandDetection] Erreur: $e');
      setState(() {
        _isModelReady = false;
        _statusMessage = 'Erreur: $e';
      });
    }
  }

  Future<void> _initCamera() async {
    try {
      if (!await _ensureCameraPermission()) {
        setState(() => _statusMessage = 'Permission caméra refusée');
        return;
      }

      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() => _statusMessage = 'Aucune caméra trouvée');
        return;
      }

      final frontCamera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _statusMessage = _isModelReady 
              ? 'Prêt - Appuyez sur DÉMARRER' 
              : 'Caméra OK, IA non chargée';
        });
      }
    } catch (e) {
      print('❌ Erreur caméra: $e');
      if (mounted) {
        setState(() => _statusMessage = 'Erreur caméra: $e');
      }
    }
  }

  void _toggleDetection() {
    if (_isLiveMode) {
      _stopDetection();
    } else {
      _startDetection();
    }
  }

  void _startDetection() {
    if (!_isCameraInitialized || !_isModelReady) {
      _showError('Caméra ou IA non prête');
      return;
    }

    setState(() {
      _isLiveMode = true;
      _detectedSign = '...';
      _confidence = 0.0;
      _statusMessage = 'Détection en cours...';
    });

    // Timer: capture photo toutes les 200ms (5 images/sec) pour temps réel
    _detectionTimer?.cancel();
    _detectionTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _captureAndDetect(),
    );
  }

  void _stopDetection() {
    _detectionTimer?.cancel();
    _detectionTimer = null;
    if (mounted) {
      setState(() {
        _isLiveMode = false;
        _detectedSign = '?';
        _confidence = 0.0;
        _statusMessage = 'Détection arrêtée';
      });
    }
  }

  Future<void> _captureAndDetect() async {
    if (_cameraController == null || 
        !_cameraController!.value.isInitialized ||
        _isDetecting) {
      return;
    }

    _isDetecting = true;
    _frameCount++;

    try {
      // 1. Prendre une photo
      final XFile photo = await _cameraController!.takePicture();
      
      // 2. Lire et décoder l'image
      final bytes = await photo.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        print('❌ Impossible de décoder l\'image');
        _isDetecting = false;
        return;
      }

      print('📸 Frame #$_frameCount - Image: ${image.width}x${image.height}');

      // 3. Envoyer à HandDetection
      await _aiService.procWithImage(image);

    } catch (e) {
      print('❌ Erreur capture/détection: $e');
    } finally {
      _isDetecting = false;
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _stopDetection();
    // TfliteAIService n'a pas de méthode dispose()
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: const Text('Détection LST'),
        backgroundColor: Colors.white,
        foregroundColor: primaryRed,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Zone caméra
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Caméra
                    _isCameraInitialized
                        ? CameraPreview(_cameraController!)
                        : const Center(
                            child: CircularProgressIndicator(color: primaryRed),
                          ),
                    // Bounding box si détection
                    if (_bbox != null && _isLiveMode)
                      CustomPaint(
                        painter: BoundingBoxPainter(
                          bbox: _bbox!,
                          label: _detectedSign,
                          confidence: _confidence,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Zone statut
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isModelReady ? Colors.green.shade100 : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _isModelReady ? Icons.check_circle : Icons.warning,
                  color: _isModelReady ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _isModelReady ? Colors.green.shade800 : Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Zone résultat
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Signe détecté',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _detectedSign.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: primaryRed,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Confiance: ${(_confidence * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStat('Frames', '$_frameCount'),
                      _buildStat('Détections', '$_detectionCount'),
                    ],
                  ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isCameraInitialized && _isModelReady ? _toggleDetection : null,
        backgroundColor: _isLiveMode ? Colors.red : primaryRed,
        icon: Icon(_isLiveMode ? Icons.stop : Icons.play_arrow),
        label: Text(_isLiveMode ? 'ARRÊTER' : 'DÉMARRER'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primaryRed,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

/// Painter pour dessiner les bounding boxes de détection
class BoundingBoxPainter extends CustomPainter {
  final List<double> bbox; // [x1, y1, x2, y2] en coordonnées normalisées (0-1)
  final String label;
  final double confidence;

  BoundingBoxPainter({
    required this.bbox,
    required this.label,
    required this.confidence,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bbox.length < 4) return;

    // Dessiner la boîte verte
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(
      bbox[0] * size.width,
      bbox[1] * size.height,
      (bbox[2] - bbox[0]) * size.width,
      (bbox[3] - bbox[1]) * size.height,
    );
    canvas.drawRect(rect, paint);

    // Dessiner le label en haut
    final text = '${label.toUpperCase()} ${(confidence * 100).toStringAsFixed(1)}%';
    final textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      backgroundColor: Colors.green,
    );
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Fond vert pour le texte
    final bgPaint = Paint()..color = Colors.green;
    canvas.drawRect(
      Rect.fromLTWH(
        bbox[0] * size.width,
        bbox[1] * size.height - textPainter.height - 4,
        textPainter.width + 8,
        textPainter.height + 4,
      ),
      bgPaint,
    );

    // Dessiner le texte
    textPainter.paint(
      canvas,
      Offset(bbox[0] * size.width + 4, bbox[1] * size.height - textPainter.height - 2),
    );
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return oldDelegate.bbox != bbox ||
        oldDelegate.label != label ||
        oldDelegate.confidence != confidence;
  }
}
