import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/simple_ai_service.dart';
import '../widgets/navigation_wrapper.dart';

const Color primaryRed = Color(0xFFE60012);
const Color bgGrey = Color(0xFFF5F5F5);

class AIDemoPage extends StatefulWidget {
  const AIDemoPage({super.key});

  @override
  State<AIDemoPage> createState() => _AIDemoPageState();
}

class _AIDemoPageState extends State<AIDemoPage> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  String _detectedLetter = '?';
  double _confidence = 0.0;
  List<String> _detectionHistory = [];
  bool _isFlashOn = false;
  bool _isStreamActive = false;
  
  final SimpleAIService _aiService = SimpleAIService.instance;

  @override
  void initState() {
    super.initState();
    print('AI Demo Page: initState called');
    _initializeCamera();
    _initializeAI();
  }

  @override
  void dispose() {
    print('AI Demo Page: dispose called');
    _stopDetectionStream();
    _cameraController?.dispose();
    _aiService.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      print('AI Demo: Initializing camera...');
      
      // Obtenir les caméras disponibles
      final cameras = await availableCameras();
      print('AI Demo: Found ${cameras.length} cameras');
      
      if (cameras.isEmpty) {
        _showError('Aucune caméra disponible');
        return;
      }
      
      // Utiliser la caméra avant pour la détection de signes
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      
      print('AI Demo: Using camera: ${frontCamera.name}');
      
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      
      print('AI Demo: Camera controller created, initializing...');
      await _cameraController!.initialize();
      print('AI Demo: Camera initialized successfully');
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('AI Demo: Camera initialization error: $e');
      _showError('Erreur d\'initialisation de la caméra: $e');
    }
  }

  Future<void> _initializeAI() async {
    try {
      print('AI Demo: Initializing AI service...');
      
      // Configurer les callbacks
      _aiService.onDetectionResult = (letter, confidence) {
        print('AI Demo: Detection result received: $letter (${(confidence * 100).toStringAsFixed(1)}%)');
        if (mounted) {
          setState(() {
            _detectedLetter = letter.toUpperCase();
            _confidence = confidence;
            
            // Ajouter à l'historique si la confiance est suffisante
            if (confidence > 0.7) {
              _detectionHistory.add(letter.toUpperCase());
              if (_detectionHistory.length > 10) {
                _detectionHistory.removeAt(0);
              }
            }
          });
        }
      };
      
      _aiService.onError = (error) {
        print('AI Demo: AI error received: $error');
        _showError('Erreur AI: $error');
      };
      
      // Initialiser les modèles
      await _aiService.initializeModels();
      print('AI Demo: AI service initialized successfully');
    } catch (e) {
      print('AI Demo: AI initialization error: $e');
      _showError('Erreur d\'initialisation AI: $e');
    }
  }

  void _startDetectionStream() {
    if (_cameraController == null) {
      print('AI Demo: Camera controller is null, cannot start stream');
      return;
    }
    
    if (!_aiService.isInitialized) {
      print('AI Demo: AI service not initialized, cannot start stream');
      return;
    }
    
    if (_isStreamActive) {
      print('AI Demo: Stream already active');
      return;
    }
    
    print('AI Demo: Starting detection stream...');
    
    try {
      _cameraController!.startImageStream((CameraImage cameraImage) {
        if (!_isDetecting && mounted) {
          _isDetecting = true;
          _aiService.processCameraFrame(cameraImage).then((_) {
            _isDetecting = false;
          }).catchError((error) {
            print('AI Demo: Error processing frame: $error');
            _isDetecting = false;
          });
        }
      });
      
      if (mounted) {
        setState(() {
          _isStreamActive = true;
        });
      }
      
      print('AI Demo: Detection stream started successfully');
    } catch (e) {
      print('AI Demo: Error starting detection stream: $e');
      _showError('Erreur lors du démarrage du stream: $e');
    }
  }

  void _stopDetectionStream() {
    if (!_isStreamActive) return;
    
    print('AI Demo: Stopping detection stream...');
    
    try {
      _cameraController?.stopImageStream();
      
      if (mounted) {
        setState(() {
          _isStreamActive = false;
        });
      }
      
      print('AI Demo: Detection stream stopped successfully');
    } catch (e) {
      print('AI Demo: Error stopping detection stream: $e');
    }
  }

  void _toggleDetection() {
    if (_isStreamActive) {
      _stopDetectionStream();
    } else {
      _startDetectionStream();
    }
  }

  void _toggleFlash() async {
    if (_cameraController == null) return;
    
    try {
      if (_isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
      } else {
        await _cameraController!.setFlashMode(FlashMode.torch);
      }
      
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      _showError('Erreur lors du changement du flash: $e');
    }
  }

  void _clearHistory() {
    setState(() {
      _detectionHistory.clear();
      _detectedLetter = '?';
      _confidence = 0.0;
    });
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
        title: const Text(
          "Demo IA - Détection de Signes",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearHistory,
          ),
        ],
      ),
      body: _isCameraInitialized ? _buildMainContent() : _buildLoadingContent(),
    );
  }

  Widget _buildLoadingContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryRed),
          SizedBox(height: 20),
          Text(
            "Initialisation de la caméra et des modèles IA...",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Zone de la caméra
        Expanded(
          flex: 3,
          child: Container(
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
                children: [
                  // Flux de la caméra
                  SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _cameraController!.value.previewSize!.height,
                        height: _cameraController!.value.previewSize!.width,
                        child: CameraPreview(_cameraController!),
                      ),
                    ),
                  ),
                  
                  // Overlay de détection
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isStreamActive ? Colors.green.withOpacity(0.9) : Colors.red.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isStreamActive ? "DETECTING" : "STOPPED",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  // Bouton de démarrage/arrêt
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: ElevatedButton(
                      onPressed: _toggleDetection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isStreamActive ? Colors.red : primaryRed,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        _isStreamActive ? "Arrêter" : "Démarrer",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  
                  // Résultat de détection
                  if (_detectedLetter != '?')
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryRed.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Signe détecté:",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _detectedLetter,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Confiance: ${(_confidence * 100).toStringAsFixed(1)}%",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
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
        ),
        
        // Zone d'information et d'historique
        Expanded(
          flex: 1,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, color: primaryRed),
                    const SizedBox(width: 8),
                    const Text(
                      "Historique de détection",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryRed,
                      ),
                    ),
                    const Spacer(),
                    if (_detectionHistory.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${_detectionHistory.length}",
                          style: const TextStyle(
                            color: primaryRed,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (_detectionHistory.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        "Aucune détection pour le moment\nCliquez sur 'Démarrer' pour commencer",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _detectionHistory.length,
                      itemBuilder: (context, index) {
                        final letter = _detectionHistory[index];
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: primaryRed.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                letter,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: primaryRed,
                                ),
                              ),
                              Text(
                                "#${index + 1}",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
