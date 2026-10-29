import 'dart:async';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import '../services/tflite_ai_service.dart';

const Color primaryRed = Color(0xFFE60012);
const Color bgGrey = Color(0xFFF5F5F5);

/// PAGE DE DÉTECTION EN TEMPS RÉEL OFFLINE (TFLITE)
///
/// Affiche un flux caméra et effectue la détection locale avec TensorFlow Lite.
class AIRealtimeBackendPage extends StatefulWidget {
  const AIRealtimeBackendPage({super.key});

  @override
  State<AIRealtimeBackendPage> createState() => _AIRealtimeBackendPageState();
}

class _AIRealtimeBackendPageState extends State<AIRealtimeBackendPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  bool _isLiveMode = false;

  String _detectedSign = '?';
  double _confidence = 0.0;
  int _frameCount = 0;
  int _detectionCount = 0;

  // Bounding box coordinates [x1, y1, x2, y2] normalisé 0-1
  List<double>? _bbox;

  final TfliteAIService _aiService = TfliteAIService.i;
  bool _isModelReady = false;

  @override
  void initState() {
    super.initState();
    _initAI();
    _initCamera();
  }

  Future<void> _initAI() async {
    _aiService.onRes = (label, conf, bbox) {
      if (!mounted) return;
      print('[UI] 🎯 onResult: label=$label conf=$conf bbox=$bbox');
      setState(() {
        _detectedSign = label;
        _confidence = conf;
        _bbox = bbox;
        if (conf > 0.5) {
          _detectionCount++;
        }
      });
      print('🎯 [TFLite] => $label (${(conf * 100).toStringAsFixed(1)}%)');
    };
    _aiService.onErr = (e) {
      print('❌ [TFLite] Erreur: $e');
      _showError('Erreur IA: $e');
    };
    await _aiService.init();
    if (mounted) {
      setState(() => _isModelReady = _aiService.isInit);
    }
  }

  @override
  void dispose() {
    // Arrêter le flux d'images d'abord
    try {
      _cameraController?.stopImageStream();
    } catch (_) {}
    // Disposer l'AI service
    // TfliteAIService n'a pas de méthode dispose()
    // Disposer la caméra
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        _showError('Aucune caméra disponible');
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
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      _showError('Erreur caméra: $e');
    }
  }

  void _toggleLiveDetection() {
    if (_isLiveMode) {
      _stopLiveDetection();
    } else {
      _startLiveDetection();
    }
  }

  void _startLiveDetection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showError('Caméra non initialisée');
      return;
    }
    if (!_isModelReady) {
      _showError('Modèles IA non chargés');
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLiveMode = true;
      _detectedSign = '...';
      _confidence = 0.0;
    });

    // Démarrer le flux d'images vers TFLite
    _cameraController!.startImageStream((CameraImage image) {
      if (!_isLiveMode || _aiService.busy) return;
      _frameCount++;
      _aiService.proc(image);
    });
  }

  void _stopLiveDetection() {
    try {
      _cameraController?.stopImageStream();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isLiveMode = false;
        _detectedSign = '?';
        _confidence = 0.0;
      });
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Détection LST - Temps Réel',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isCameraInitialized ? _buildBody() : _buildLoading(),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryRed),
          SizedBox(height: 20),
          Text('Initialisation de la caméra...'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Zone caméra avec hauteur fixe
          Container(
            height: MediaQuery.of(context).size.height * 0.55,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Preview caméra - simple sans AspectRatio
                  CameraPreview(_cameraController!),

                  // Overlay des bounding boxes
                  if (_bbox != null)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: BoundingBoxPainter(
                          bbox: _bbox!,
                          label: _detectedSign,
                          confidence: _confidence,
                        ),
                      ),
                    ),
                  // Indicateur visuel forcé quand IA active
                  if (_bbox != null)
                    Positioned(
                      top: 50,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.red,
                        child: Text(
                          'IA ACTIVE: ${_detectedSign.toUpperCase()}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                  // Overlay statut
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isLiveMode ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isLiveMode ? 'LIVE' : 'PAUSE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Overlay résultat
                  if (_isLiveMode)
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryRed.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.sign_language, color: Colors.white, size: 32),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Signe détecté:',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    _detectedSign.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_confidence > 0)
                                    Text(
                                      'Confiance: ${(_confidence * 100).toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

        // Zone infos
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, color: primaryRed),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Instructions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_isDetecting)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryRed,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow('1.', 'Appuyez sur le bouton ▶ pour démarrer'),
              _buildInfoRow('2.', 'Placez votre main devant la caméra'),
              _buildInfoRow('3.', 'Le signe apparaît en bas de l\'écran'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('Frames', '$_frameCount'),
                  _buildStat('Détections', '$_detectionCount'),
                  _buildStat('Confiance', '${(_confidence * 100).toStringAsFixed(0)}%'),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildInfoRow(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: const TextStyle(
              color: primaryRed,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryRed,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget? _buildFab() {
    if (!_isCameraInitialized) return null;
    return FloatingActionButton.extended(
      onPressed: _toggleLiveDetection,
      backgroundColor: _isLiveMode ? Colors.red : primaryRed,
      icon: Icon(_isLiveMode ? Icons.stop : Icons.play_arrow),
      label: Text(_isLiveMode ? 'ARRÊTER' : 'DÉMARRER'),
    );
  }
}

/// Painter pour dessiner les bounding boxes de détection
class BoundingBoxPainter extends CustomPainter {
  final List<double> bbox; // [x1, y1, x2, y2] normalisé 0-1
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

    // Coordonnées normalisées → pixels
    final double x1 = bbox[0] * size.width;
    final double y1 = bbox[1] * size.height;
    final double x2 = bbox[2] * size.width;
    final double y2 = bbox[3] * size.height;
    final double boxWidth = x2 - x1;
    final double boxHeight = y2 - y1;

    // Style du rectangle (bordure verte épaisse)
    final paint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // Dessiner le rectangle
    canvas.drawRect(Rect.fromLTWH(x1, y1, boxWidth, boxHeight), paint);

    // Préparer le texte (label + confiance)
    final String displayText = '${label.toUpperCase()} ${(confidence * 100).toStringAsFixed(1)}%';

    final textPainter = TextPainter(
      text: TextSpan(
        text: displayText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.greenAccent,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(x1, y1 - textPainter.height - 4));
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return oldDelegate.bbox != bbox ||
        oldDelegate.label != label ||
        oldDelegate.confidence != confidence;
  }
}
