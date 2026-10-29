import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/navigation_wrapper.dart';
import 'dictionary_page.dart';

const Color primaryRed = Color(0xFFE60012);
const Color bgGrey = Color(0xFFF5F5F5);
const Color lightPink = Color(0xFFFBEDED);

// PAGE DE JEU DE RECONNAISSANCE DE SIGNES
class SignRecognitionGame extends StatefulWidget {
  const SignRecognitionGame({super.key});

  @override
  State<SignRecognitionGame> createState() => _SignRecognitionGameState();
}

class _SignRecognitionGameState extends State<SignRecognitionGame> {
  // État du jeu
  int _currentSignIndex = 0;
  int _score = 0;
  int _attempts = 0;
  bool _isGameStarted = false;
  bool _isCameraActive = false;
  bool _isPhotoTaken = false;
  String? _capturedImagePath;
  String? _detectedSign;
  double? _confidence;
  bool _isLoading = false;

  // Caméra
  CameraController? cameraController;
  List<CameraDescription>? cameras;
  bool isCameraInitialized = false;
  bool isCameraAvailable = true;

  // Liste des signes à deviner (utilisant les vraies données du dictionnaire)
  final List<Sign> _signs = [
    Sign(
      id: 1,
      title: "Maman",
      arabicWord: "أمي",
      category: "Famille",
      imagePath: "dictionnaire_DB/ommi-maman/1.png",
      explanationImage: "dictionnaire_DB/ommi-maman/2.png",
      description: "Faites le signe pour maman",
      synonyms: ["Mère", "Maman"],
    ),
    Sign(
      id: 2,
      title: "Maison",
      arabicWord: "دار",
      category: "Lieux",
      imagePath: "dictionnaire_DB/dar-maison/1.png",
      explanationImage: "dictionnaire_DB/dar-maison/2.png",
      description: "Faites le signe pour maison",
      synonyms: ["Maison", "Domicile", "Chez soi"],
    ),
    Sign(
      id: 3,
      title: "Soeur",
      arabicWord: "أختي",
      category: "Famille",
      imagePath: "dictionnaire_DB/okhti-soeur/1.png",
      explanationImage: "dictionnaire_DB/okhti-soeur/2.png",
      description: "Faites le signe pour soeur",
      synonyms: ["Soeur", "Sœur"],
    ),
    Sign(
      id: 4,
      title: "Carte",
      arabicWord: "كارت",
      category: "Objets",
      imagePath: "dictionnaire_DB/carta-carte/1.png",
      explanationImage: "dictionnaire_DB/carta-carte/2.png",
      description: "Faites le signe pour carte",
      synonyms: ["Carte", "Document"],
    ),
    Sign(
      id: 5,
      title: "Danser",
      arabicWord: "يختاح",
      category: "Actions",
      imagePath: "dictionnaire_DB/yachtah-dance/1.png",
      explanationImage: "dictionnaire_DB/yachtah-dance/2.png",
      description: "Faites le signe pour danser",
      synonyms: ["Danser", "Dance"],
    ),
    Sign(
      id: 6,
      title: "Centre",
      arabicWord: "مركز",
      category: "Lieux",
      imagePath: "dictionnaire_DB/centre-centre/1.png",
      explanationImage: "dictionnaire_DB/centre-centre/2.png",
      description: "Faites le signe pour centre",
      synonyms: ["Centre", "Center"],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) {
        cameraController = CameraController(
          cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        
        await cameraController!.initialize();
        
        if (mounted) {
          setState(() {
            isCameraInitialized = true;
            isCameraAvailable = true;
          });
        }
      }
    } catch (e) {
      print('Erreur initialisation caméra: $e');
      if (mounted) {
        setState(() {
          isCameraAvailable = false;
        });
      }
    }
  }

  void _startGame() {
    setState(() {
      _isGameStarted = true;
      _currentSignIndex = 0;
      _score = 0;
      _attempts = 0;
    });
  }

  void _startCamera() {
    setState(() {
      _isCameraActive = true;
      _isPhotoTaken = false;
      _capturedImagePath = null;
      _detectedSign = null;
      _confidence = null;
    });
  }

  Future<void> _takePhoto() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Caméra non initialisée")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final XFile image = await cameraController!.takePicture();
      final imageBytes = await image.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      setState(() {
        _capturedImagePath = base64Image;
        _isPhotoTaken = true;
        _isLoading = false;
      });

      // Simuler la détection (remplacer par votre modèle IA plus tard)
      _simulateAIDetection();

    } catch (e) {
      print('Erreur capture: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la capture: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _simulateAIDetection() {
    // Simulation de détection IA (remplacer par votre vrai modèle)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final currentSign = _signs[_currentSignIndex];
        final correctDetection = (DateTime.now().millisecond % 3) == 0; // 33% de chance de bonne réponse
        
        setState(() {
          _detectedSign = correctDetection ? currentSign.title : _signs[(DateTime.now().millisecond % _signs.length)].title;
          _confidence = correctDetection ? 0.85 + (DateTime.now().millisecond % 10) / 100 : 0.45 + (DateTime.now().millisecond % 20) / 100;
          _attempts++;
          
          if (_detectedSign == currentSign.title) {
            _score++;
          }
        });

        _showDetectionResult();
      }
    });
  }

  void _showDetectionResult() {
    final currentSign = _signs[_currentSignIndex];
    final isCorrect = _detectedSign == currentSign.title;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCorrect ? Colors.green : Colors.red,
                width: 3,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  size: 60,
                  color: isCorrect ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 15),
                Text(
                  isCorrect ? 'Excellent !' : 'Essayez encore !',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isCorrect ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Signe détecté: $_detectedSign',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Confiance: ${(_confidence! * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 16,
                    color: _confidence! > 0.8 ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(height: 20),
                if (_capturedImagePath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      base64Decode(_capturedImagePath!),
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (!isCorrect)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _startCamera(); // Réessayer
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Réessayer'),
                      ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _nextSign();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryRed,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(isCorrect ? 'Suivant' : 'Passer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _nextSign() {
    setState(() {
      _isCameraActive = false;
      _isPhotoTaken = false;
      _capturedImagePath = null;
      _detectedSign = null;
      _confidence = null;
      
      if (_currentSignIndex < _signs.length - 1) {
        _currentSignIndex++;
      } else {
        _showGameResults();
      }
    });
  }

  void _showGameResults() {
    setState(() {
      _isGameStarted = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryRed, width: 3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events,
                  size: 60,
                  color: primaryRed,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Jeu terminé !',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryRed,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'Score: $_score/${_signs.length}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Précision: ${((_score / _signs.length) * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Tentatives: $_attempts',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _startGame(); // Recommencer
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Recommencer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(); // Retour au menu
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Retour au menu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSign = _signs[_currentSignIndex];

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
          'Jeu de Reconnaissance',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isGameStarted)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  'Score: $_score/${_signs.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (!_isGameStarted) ...[
              // Écran d'accueil
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryRed.withOpacity(0.8), primaryRed],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.sign_language,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Jeu de Reconnaissance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Reproduisez les signes avec votre caméra',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryRed,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Commencer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Écran de jeu
              if (!_isCameraActive) ...[
                // Affichage du signe à reproduire
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Signe ${_currentSignIndex + 1}/${_signs.length}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryRed,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Image du signe depuis le dictionnaire
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: bgGrey,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            currentSign.imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Image non trouvée',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        currentSign.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        currentSign.arabicWord,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        currentSign.description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _startCamera,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Commencer la capture'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Écran caméra
                Container(
                  width: double.infinity,
                  height: 400,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(25),
                    color: const Color(0xFF2a3a52),
                  ),
                  child: Stack(
                    children: [
                      // Caméra
                      if (isCameraAvailable && isCameraInitialized && cameraController != null && !_isPhotoTaken)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: cameraController!.value.previewSize!.height,
                                height: cameraController!.value.previewSize!.width,
                                child: CameraPreview(cameraController!),
                              ),
                            ),
                          ),
                        ),
                      
                      // Photo capturée
                      if (_isPhotoTaken && _capturedImagePath != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.memory(
                            base64Decode(_capturedImagePath!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      
                      // Overlay pendant l'analyse
                      if (_isLoading)
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: Colors.black.withOpacity(0.7),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
                              ),
                              SizedBox(height: 20),
                              Text(
                                'Analyse en cours...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Boutons de contrôle
                if (!_isPhotoTaken)
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      label: const Text('Capturer le signe', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
