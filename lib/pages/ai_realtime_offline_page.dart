import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/tflite_ai_service.dart';

class AIRealtimeOfflinePage extends StatefulWidget {
  const AIRealtimeOfflinePage({Key? key}) : super(key: key);

  @override
  _AIRealtimeOfflinePageState createState() => _AIRealtimeOfflinePageState();
}

class _AIRealtimeOfflinePageState extends State<AIRealtimeOfflinePage>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isDetecting = false;
  bool _modelReady = false;
  String _currentSign = '...';
  double _confidence = 0.0;
  int _frameCount = 0;
  int _detectionCount = 0;
  String _status = 'Chargement modèles...';
  List<double>? _bbox; // [x1, y1, x2, y2] normalisé

  late TfliteAIService _ai;
  Timer? _captureTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ai = TfliteAIService.i;
    _ai.onRes = (label, conf, bbox) {
      if (!mounted) return;
      print('[UI] 🎯 onResult: label=$label conf=$conf bbox=$bbox');
      setState(() {
        _currentSign = label;
        _confidence = conf;
        _detectionCount++;
        _bbox = bbox;
      });
      _saveDetection(label, conf);
    };
    _ai.onErr = (err) {
      if (!mounted) return;
      setState(() => _status = err);
    };
    _initAll();
  }

  Future<void> _initAll() async {
    await _ai.init();
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      setState(() => _status = 'Aucune caméra');
      return;
    }
    await _initCamera();
    setState(() {
      _modelReady = _ai.isInit;
      _status = _modelReady ? 'Prêt (offline)' : 'Erreur modèle';
    });
  }

  Future<void> _initCamera() async {
    final front = _cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras.first,
    );
    _cameraController = CameraController(
      front,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await _cameraController!.initialize();
    if (!mounted) return;
    setState(() {});
    _startDetection();
  }

  void _startDetection() {
    if (_isDetecting || _cameraController == null || !_cameraController!.value.isInitialized) return;
    _isDetecting = true;
    _cameraController!.startImageStream((CameraImage img) async {
      _frameCount++;
      await _ai.proc(img);
    });
    setState(() => _status = 'Détection en cours (offline)');
  }

  void _stopDetection() {
    _cameraController?.stopImageStream();
    _isDetecting = false;
    setState(() => _status = 'Détection arrêtée');
  }

  Future<void> _saveDetection(String sign, double conf) async {
    if (conf < 0.5) return;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toIso8601String();
    final history = prefs.getStringList('detection_history_offline') ?? [];
    history.insert(0, '$now|${sign.toUpperCase()}|${(conf * 100).toStringAsFixed(0)}');
    if (history.length > 50) history.removeLast();
    await prefs.setStringList('detection_history_offline', history);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopDetection();
    _cameraController?.dispose();
    // TfliteAIService n'a pas de méthode dispose()
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détection Offline 100%'),
        backgroundColor: const Color(0xFF3B82F6),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfo(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _cameraController != null && _cameraController!.value.isInitialized
                    ? CameraPreview(_cameraController!)
                    : Container(color: Colors.black, child: const Center(child: CircularProgressIndicator())),
                // Overlay bounding box
                if (_bbox != null)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: BBoxPainter(bbox: _bbox!, label: _currentSign, confidence: _confidence),
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
                        'IA ACTIVE: ${_currentSign.toUpperCase()}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                Positioned(
                  top: 16, left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                    child: Text(_status, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
                Positioned(
                  bottom: 100, left: 0, right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentSign.toUpperCase(),
                            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Confiance: ${(_confidence * 100).toStringAsFixed(0)}%',
                            style: TextStyle(fontSize: 16, color: _confidence > 0.6 ? Colors.green : Colors.orange),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCounter('Frames', _frameCount.toString()),
                        _buildCounter('Détections', _detectionCount.toString()),
                        _buildCounter('Confiance', '${(_confidence * 100).toStringAsFixed(0)}%'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isDetecting ? _stopDetection : _startDetection,
                        icon: Icon(_isDetecting ? Icons.stop : Icons.play_arrow),
                        label: Text(_isDetecting ? 'Arrêter' : 'Démarrer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isDetecting ? Colors.red : const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounter(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mode Offline'),
        content: const Text(
          'Les modèles TFLite tournent directement sur votre téléphone.\n\n'
          'Aucune connexion internet requise, aucun serveur backend.\n\n'
          'Si les modèles ne sont pas encore convertis, exécutez :\n'
          'python modele-ai-camera/convert_to_tflite.py',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }
}

/// Dessine le rectangle de détection et le label sur la caméra
class BBoxPainter extends CustomPainter {
  final List<double> bbox; // [x1, y1, x2, y2] normalisé 0-1
  final String label;
  final double confidence;

  BBoxPainter({required this.bbox, required this.label, required this.confidence});

  @override
  void paint(Canvas canvas, Size size) {
    print('[Painter] paint() called size=$size bbox=$bbox');
    if (bbox.length < 4) return;

    final x1 = bbox[0] * size.width;
    final y1 = bbox[1] * size.height;
    final x2 = bbox[2] * size.width;
    final y2 = bbox[3] * size.height;
    final w = x2 - x1;
    final h = y2 - y1;

    // Rectangle vert
    final paint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawRect(Rect.fromLTWH(x1, y1, w, h), paint);

    // Label avec fond vert (sécurisé X et Y)
    final text = '${label.toUpperCase()} ${(confidence * 100).toStringAsFixed(1)}%';
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Clamp X et Y pour que le texte reste toujours dans l'écran
    final textY = (y1 - textPainter.height - 4).clamp(4.0, size.height - textPainter.height - 4);
    final textX = x1.clamp(0.0, size.width - textPainter.width - 8);

    // Fond vert pour la lisibilité
    canvas.drawRect(
      Rect.fromLTWH(textX, textY, textPainter.width + 8, textPainter.height),
      Paint()..color = Colors.green,
    );

    textPainter.paint(canvas, Offset(textX + 4, textY));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
