import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/simple_ai_service.dart';
import '../widgets/navigation_wrapper.dart';

const Color primaryRed = Color(0xFFE60012);
const Color bgGrey = Color(0xFFF5F5F5);

class AIRecognitionPage extends StatefulWidget {
  const AIRecognitionPage({super.key});

  @override
  State<AIRecognitionPage> createState() => _AIRecognitionPageState();
}

class _AIRecognitionPageState extends State<AIRecognitionPage> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  String _detectedLetter = '?';
  double _confidence = 0.0;
  List<String> _detectionHistory = [];
  int _frameCount = 0;
  
  final SimpleAIService _aiService = SimpleAIService.instance;

  @override
  void initState() {
    super.initState();
    print('AI Recognition Page: initState called');
    _initializeCamera();
    _initializeAI();
  }

  @override
  void dispose() {
    print('AI Recognition Page: dispose called');
    _cameraController?.dispose();
    _aiService.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      print('AI Recognition: Initializing camera...');
      
      // Obtenir les caméras disponibles
      final cameras = await availableCameras();
      print('AI Recognition: Found ${cameras.length} cameras');
      
      if (cameras.isEmpty) {
        _showError('Aucune caméra disponible');
        return;
      }
      
      // Utiliser la caméra avant pour la détection de signes (mieux pour les mains)
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      
      print('AI Recognition: Using camera: ${frontCamera.name}');
      
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium, // Réduire la résolution pour de meilleures performances
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      
      print('AI Recognition: Camera controller created, initializing...');
      await _cameraController!.initialize();
      print('AI Recognition: Camera initialized successfully');
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        
        // Démarrer IMMÉDIATEMENT le stream de détection en temps réel
        _startRealTimeDetection();
      }
    } catch (e) {
      print('AI Recognition: Camera initialization error: $e');
      _showError('Erreur d\'initialisation de la caméra: $e');
    }
  }

  Future<void> _initializeAI() async {
    try {
      print('AI Recognition: Initializing AI service...');
      
      // Configurer les callbacks
      _aiService.onDetectionResult = (letter, confidence) {
        print('AI Recognition: Detection result received: $letter (${(confidence * 100).toStringAsFixed(1)}%)');
        if (mounted) {
          setState(() {
            _detectedLetter = letter.toUpperCase();
            _confidence = confidence;
            
            // Ajouter à l'historique si la confiance est suffisante
            if (confidence > 0.7) {
              _detectionHistory.add(letter.toUpperCase());
              if (_detectionHistory.length > 15) {
                _detectionHistory.removeAt(0);
              }
            }
          });
        }
      };
      
      _aiService.onError = (error) {
        print('AI Recognition: AI error received: $error');
        _showError('Erreur AI: $error');
      };
      
      // Initialiser les modèles
      await _aiService.initializeModels();
      print('AI Recognition: AI service initialized successfully');
    } catch (e) {
      print('AI Recognition: AI initialization error: $e');
      _showError('Erreur d\'initialisation AI: $e');
    }
  }

  void _startRealTimeDetection() {
    if (_cameraController == null) {
      print('AI Recognition: Camera controller is null, cannot start stream');
      return;
    }
    
    if (!_aiService.isInitialized) {
      print('AI Recognition: AI service not initialized, cannot start stream');
      return;
    }
    
    print('AI Recognition: Starting REAL-TIME detection stream...');
    
    try {
      _cameraController!.startImageStream((CameraImage cameraImage) {
        _frameCount++;
        
        // Traiter CHAQUE frame pour la détection en temps réel
        if (!_isDetecting && mounted) {
          _isDetecting = true;
          
          // Envoyer la frame au service AI pour détection IMMÉDIATE
          _aiService.processCameraFrame(cameraImage).then((_) {
            _isDetecting = false;
          }).catchError((error) {
            print('AI Recognition: Error processing frame: $error');
            _isDetecting = false;
          });
        }
        
        // Log toutes les 120 frames pour éviter trop de logs
        if (_frameCount % 120 == 0) {
          print('AI Recognition: Processed $_frameCount frames - REAL-TIME ACTIVE');
        }
      });
      
      print('AI Recognition: REAL-TIME detection stream started successfully');
    } catch (e) {
      print('AI Recognition: Error starting detection stream: $e');
      _showError('Erreur lors du démarrage du stream: $e');
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
        title: const Text(
          "Reconnaissance IA - Temps Réel",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        // PAS DE BOUTONS DANS L'APPBAR - JUSTE LE RETOUR
      ),
      body: _isCameraInitialized ? _buildRealTimeContent() : _buildLoadingContent(),
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
            "Initialisation de la caméra...",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 10),
          Text(
            "Démarrage de la détection en temps réel...",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRealTimeContent() {
    return Column(
      children: [
        // Zone de la caméra TOUJOURS ACTIVE - PAS DE BOUTONS
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
                  // Flux de la caméra TOUJOURS ACTIF en temps réel
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
                  
                  // Overlay de statut - TOUJOURS DETECTING
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.9), // TOUJOURS VERT
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
                          const Text(
                            "DETECTING", // TOUJOURS DETECTING
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Indicateur de frame processing
                  Positioned(
                    top: 20,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Frame: $_frameCount",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  // Résultat de détection en temps réel - TOUJOURS VISIBLE
                  Positioned(
                    bottom: 20,
                    left: 20,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Signe détecté:",
                            style: TextStyle(
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
                  
                  // PAS DE BOUTON DE CONTRÔLE - LA DÉTECTION EST TOUJOURS ACTIVE
                ],
              ),
            ),
          ),
        ),
        
        // Zone d'information et d'historique - PAS DE BOUTONS
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
                      "Détection en temps réel",
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.camera_alt,
                            size: 48,
                            color: primaryRed,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Détection active en temps réel\nMontrez votre main devant la caméra",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
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
