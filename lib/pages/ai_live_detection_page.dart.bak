import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/navigation_wrapper.dart';

const Color primaryRed = Color(0xFFE60012);
const Color bgGrey = Color(0xFFF5F5F5);

// PAGE DE DÉTECTION IA EN TEMPS RÉEL
class AILiveDetectionPage extends StatefulWidget {
  const AILiveDetectionPage({super.key});

  @override
  State<AILiveDetectionPage> createState() => _AILiveDetectionPageState();
}

class _AILiveDetectionPageState extends State<AILiveDetectionPage> {
  bool _isPythonRunning = false;
  String _lastDetectedSign = 'En attente...';
  double _lastConfidence = 0.0;
  int _detectionCount = 0;
  List<String> _detectionHistory = [];

  @override
  void initState() {
    super.initState();
    _loadDetectionHistory();
  }

  Future<void> _loadDetectionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('live_detection_history') ?? [];
    setState(() {
      _detectionHistory = history;
    });
  }

  Future<void> _saveToHistory(String sign) async {
    final prefs = await SharedPreferences.getInstance();
    _detectionHistory.insert(0, sign);
    if (_detectionHistory.length > 10) {
      _detectionHistory = _detectionHistory.take(10).toList();
    }
    await prefs.setStringList('live_detection_history', _detectionHistory);
    setState(() {});
  }

  Future<void> _startPythonDetection() async {
    if (_isPythonRunning) {
      _stopPythonDetection();
      return;
    }

    setState(() {
      _isPythonRunning = true;
      _lastDetectedSign = 'Démarrage...';
    });

    try {
      // Lancer le script Python amélioré pour Flutter
      final result = await Process.run('python', [
        'modele-ai-camera/camera_flutter.py'
      ], workingDirectory: 'c:\\Users\\Lenovo\\Documents\\app_p2m');

      if (result.exitCode == 0) {
        print('✅ Script Python démarré avec succès');
        print('📤 Sortie: ${result.stdout}');
        
        // Lancer la surveillance du fichier JSON pour les détections en temps réel
        _monitorDetectionFile();
      } else {
        print('❌ Erreur script Python: ${result.stderr}');
        setState(() {
          _lastDetectedSign = 'Erreur de démarrage';
          _isPythonRunning = false;
        });
      }
    } catch (e) {
      print('❌ Erreur lancement Python: $e');
      setState(() {
        _lastDetectedSign = 'Erreur: $e';
        _isPythonRunning = false;
      });
    }
  }

  void _monitorDetectionFile() {
    // Surveiller le fichier JSON pour les détections en temps réel
    Future.delayed(const Duration(seconds: 1), () async {
      if (!_isPythonRunning || !mounted) return;

      try {
        final file = File('c:\\Users\\Lenovo\\Documents\\app_p2m\\detection_results.json');
        if (await file.exists()) {
          final content = await file.readAsString();
          if (content.isNotEmpty) {
            final data = jsonDecode(content);
            
            if (data['status'] != 'stopped' && data['detections'] != null) {
              final detections = List<Map<String, dynamic>>.from(data['detections']);
              if (detections.isNotEmpty) {
                // Prendre la détection avec la plus haute confiance
                final bestDetection = detections.reduce((a, b) => a['confidence'] > b['confidence'] ? a : b);
                
                if (bestDetection['sign'] != _lastDetectedSign) {
                  setState(() {
                    _lastDetectedSign = bestDetection['sign'];
                    _lastConfidence = bestDetection['confidence'];
                    _detectionCount++;
                  });
                  
                  _saveToHistory(bestDetection['sign']);
                  print('🎯 Nouvelle détection: ${bestDetection['sign']} (${(bestDetection['confidence'] * 100).toStringAsFixed(1)}%)');
                }
              }
            }
          }
        }
      } catch (e) {
        print('❌ Erreur lecture fichier JSON: $e');
      }
      
      // Continuer la surveillance
      _monitorDetectionFile();
    });
  }

  Future<void> _stopPythonDetection() async {
    setState(() {
      _isPythonRunning = false;
      _lastDetectedSign = 'Arrêté';
    });

    try {
      // Arrêter tous les processus Python
      await Process.run('taskkill', ['/F', '/IM', 'python.exe']);
      print('🛑 Script Python arrêté');
    } catch (e) {
      print('❌ Erreur arrêt Python: $e');
    }
  }

  @override
  void dispose() {
    _stopPythonDetection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a2332),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Détection IA en Direct',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isPythonRunning ? Icons.stop : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: _startPythonDetection,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Zone de statut
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isPythonRunning 
                    ? [primaryRed.withOpacity(0.8), primaryRed]
                    : [Colors.grey.withOpacity(0.8), Colors.grey],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    _isPythonRunning ? Icons.videocam : Icons.videocam_off,
                    size: 60,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _isPythonRunning ? 'DÉTECTION EN COURS' : 'DÉTECTION ARRÊTÉE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isPythonRunning 
                        ? 'Le modèle Python analyse vos signes en temps réel'
                        : 'Appuyez sur play pour démarrer la détection',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Dernière détection
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dernière détection',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _lastDetectedSign,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: primaryRed,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Confiance: ${(_lastConfidence * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 16,
                                color: _lastConfidence > 0.8 
                                  ? Colors.green 
                                  : _lastConfidence > 0.6 
                                    ? Colors.orange 
                                    : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: primaryRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Icon(
                          Icons.sign_language,
                          color: primaryRed,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Statistiques
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$_detectionCount',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryRed,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Détections',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${_detectionHistory.length}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryRed,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Historique',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Historique récent
            if (_detectionHistory.isNotEmpty) ...[
              const Text(
                'Historique récent',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: _detectionHistory.take(5).map((sign) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: primaryRed,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              sign,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 30),

            // Instructions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📋 Instructions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildInstruction('1. Cliquez sur Play pour démarrer la détection'),
                  _buildInstruction('2. Signez devant votre caméra'),
                  _buildInstruction('3. Le modèle détecte les signes en temps réel'),
                  _buildInstruction('4. Cliquez sur Stop pour arrêter'),
                  _buildInstruction('5. L\'historique sauvegarde vos détections'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 16,
              color: Colors.blue[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
