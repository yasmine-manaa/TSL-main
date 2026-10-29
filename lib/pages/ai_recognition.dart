import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/navigation_wrapper.dart';
import '../services/backend_ai_service.dart';
// import 'ai_live_detection_page.dart';

// MODÈLE DE DONNÉES POUR L'HISTORIQUE
class CaptureHistory {
  final String imageBase64;
  final String detectedSign;
  final String detectedWord;
  final double confidence;
  final int timestamp;
  
  CaptureHistory({
    required this.imageBase64,
    required this.detectedSign,
    required this.detectedWord,
    required this.confidence,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'imageBase64': imageBase64,
      'detectedSign': detectedSign,
      'detectedWord': detectedWord,
      'confidence': confidence,
      'timestamp': timestamp,
    };
  }
  
  factory CaptureHistory.fromJson(Map<String, dynamic> json) {
    return CaptureHistory(
      imageBase64: json['imageBase64'],
      detectedSign: json['detectedSign'],
      detectedWord: json['detectedWord'],
      confidence: json['confidence'].toDouble(),
      timestamp: json['timestamp'],
    );
  }
}

const Color primaryRed = Color(0xFFE60012);
const Color bgGrey = Color(0xFFF5F5F5);

// PAGE DE RECONNAISSANCE IA PAR CAMÉRA
class AIRecognitionPage extends StatefulWidget {
  const AIRecognitionPage({super.key});

  @override
  State<AIRecognitionPage> createState() => _AIRecognitionPageState();
}

class _AIRecognitionPageState extends State<AIRecognitionPage> {
  bool isLoading = false;
  String? detectedSign;
  String? detectedWord;
  double? confidence;
  CameraController? cameraController;
  List<CameraDescription>? cameras;
  bool isCameraInitialized = false;
  bool isCameraAvailable = true;
  String? capturedImagePath; // Pour stocker l'image capturée
  bool showCapturedImage = false; // Pour afficher l'image capturée

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
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

  // Initialiser la caméra
  Future<void> _initializeCamera() async {
    try {
      if (!await _ensureCameraPermission()) {
        if (mounted) {
          setState(() {
            isCameraAvailable = false;
          });
        }
        return;
      }

      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) {
        cameraController = CameraController(
          cameras![0], // Utiliser la première caméra disponible
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
      } else {
        if (mounted) {
          setState(() {
            isCameraAvailable = false;
          });
        }
      }
    } catch (e) {
      print('Erreur d\'initialisation de la caméra: $e');
      if (mounted) {
        setState(() {
          isCameraAvailable = false;
        });
      }
    }
  }

  // FONCTION POUR ENVOYER L'IMAGE AU MODÈLE IA
  Future<void> _recognizeSignFromCamera() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Caméra non initialisée")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Capturer une image depuis la caméra
      final XFile image = await cameraController!.takePicture();
      
      // Lire les bytes de l'image capturée
      final imageBytes = await image.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      
      // Afficher l'image capturée avec une pause (sans sauvegarder encore)
      setState(() {
        capturedImagePath = base64Image;
        showCapturedImage = true;
        isLoading = false;
      });
      
      print('📸 Photo capturée avec succès!');
      print('📏 Taille de l\'image: ${imageBytes.length} bytes');
      
      // Message de confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("📸 Photo capturée! Choisissez: Analyser ou Reprendre"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      print('❌ Erreur lors de la capture: $e');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la capture: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fonction pour réactiver la caméra
  Future<void> _resumeCamera() async {
    print('🔄 Début _resumeCamera...');
    print('🔄 showCapturedImage avant: $showCapturedImage');
    
    // Forcer la reconstruction avec setState
    setState(() {
      showCapturedImage = false;
      capturedImagePath = null;
      detectedSign = null;
      detectedWord = null;
      confidence = null;
    });
    
    // Attendre un peu pour que setState s'exécute
    await Future.delayed(const Duration(milliseconds: 100));
    
    print('🔄 showCapturedImage après: $showCapturedImage');
    print('🔄 isCameraAvailable: $isCameraAvailable');
    print('🔄 isCameraInitialized: $isCameraInitialized');
    print('🔄 cameraController != null: ${cameraController != null}');
    print('📹 Caméra de retour en mode actif!');
  }

  // Fonction pour analyser l'image capturée
  Future<void> _analyzeCapturedImage() async {
    if (capturedImagePath == null) return;
    
    setState(() => isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Sauvegarder l'image capturée (ancien système)
      await prefs.setString('captured_sign_$timestamp', capturedImagePath!);
      await prefs.setString('last_captured_sign', capturedImagePath!);
      
      print('💾 Image sauvegardée avec timestamp: $timestamp');
      
      // === APPEL AU BACKEND IA RÉEL ===
      final aiService = BackendAIService();
      
      // Vérifier que le backend est accessible (optionnel, pour feedback rapide)
      final isHealthy = await aiService.healthCheck();
      if (!isHealthy) {
        throw Exception(
          'Backend IA injoignable sur ${aiService.baseUrl}. Vérifiez que le serveur Flask est lancé (python backend/api.py) et que l\'IP est correcte.',
        );
      }

      print('🚀 Envoi de l\'image au backend pour analyse vers ${aiService.baseUrl}...');
      final result = await aiService.detectFromBase64(capturedImagePath!);
      print('📥 Réponse backend: $result');
      
      final bool detected = result['detected'] ?? false;
      final String sign = detected ? (result['sign'] ?? '?') : 'Aucun signe';
      final double conf = detected ? ((result['confidence'] ?? 0.0) as double) : 0.0;
      
      setState(() {
        detectedSign = sign;
        detectedWord = sign; // Le modèle détecte des lettres/chiffres; on peut mapper vers des mots plus tard
        confidence = conf;
        isLoading = false;
      });
      
      // Sauvegarder les informations de l'analyse
      await prefs.setString('last_detected_sign', sign);
      await prefs.setString('last_detected_word', sign);
      await prefs.setDouble('last_confidence', conf);
      
      // 🆕 SAUVEGARDER DANS L'HISTORIQUE
      await _saveToHistory(
        capturedImagePath!,
        sign,
        sign,
        conf,
        timestamp,
      );
      
      print('📊 Analyse sauvegardée: $sign - ${(conf * 100).toStringAsFixed(0)}%');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              detected
                ? "✅ Signe détecté: $sign (${(conf * 100).toStringAsFixed(0)}%)"
                : "⚠️ Aucun signe détecté",
            ),
            backgroundColor: detected ? Colors.blue : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur lors de l\'analyse: $e');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'analyse: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 🆕 Fonction pour sauvegarder dans l'historique (max 5 images)
  Future<void> _saveToHistory(
    String imageBase64,
    String sign,
    String word,
    double confidence,
    int timestamp,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Récupérer l'historique existant
      final historyJson = prefs.getStringList('capture_history') ?? [];
      List<CaptureHistory> history = historyJson
          .map((json) => CaptureHistory.fromJson(jsonDecode(json)))
          .toList();
      
      // Ajouter la nouvelle capture
      final newCapture = CaptureHistory(
        imageBase64: imageBase64,
        detectedSign: sign,
        detectedWord: word,
        confidence: confidence,
        timestamp: timestamp,
      );
      
      history.insert(0, newCapture); // Ajouter au début
      
      // Garder seulement les 5 dernières
      if (history.length > 5) {
        history = history.take(5).toList();
      }
      
      // Convertir en JSON et sauvegarder
      final historyToJson = history.map((item) => jsonEncode(item.toJson())).toList();
      await prefs.setStringList('capture_history', historyToJson);
      
      print('📚 Historique sauvegardé: ${history.length} captures');
    } catch (e) {
      print('❌ Erreur sauvegarde historique: $e');
    }
  }

  void _resetRecognition() {
    setState(() {
      detectedSign = null;
      detectedWord = null;
      confidence = null;
      capturedImagePath = null;
      showCapturedImage = false;
    });
  }

  // Voir la dernière photo capturée
  Future<void> _viewLastCapturedPhoto() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastPhoto = prefs.getString('last_captured_sign');
      
      if (lastPhoto != null) {
        // Récupérer les informations de la dernière analyse
        final lastSign = prefs.getString('last_detected_sign') ?? 'Non analysé';
        final lastWord = prefs.getString('last_detected_word') ?? 'N/A';
        final lastConfidence = prefs.getDouble('last_confidence') ?? 0.0;
        
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFF1a2332),
                  border: Border.all(color: primaryRed, width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header avec informations sur le signe
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: primaryRed,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "📸 Dernière photo capturée",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (lastSign != 'Non analysé')
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Signe détecté: $lastSign",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "Traduction: $lastWord",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Text(
                                      "Confiance: ${(lastConfidence * 100).toStringAsFixed(0)}%",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // Barre de confiance
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(5),
                                        child: LinearProgressIndicator(
                                          value: lastConfidence,
                                          minHeight: 6,
                                          backgroundColor: Colors.white.withOpacity(0.3),
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            lastConfidence > 0.8 ? Colors.green : 
                                            lastConfidence > 0.6 ? Colors.yellow : Colors.red,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          else
                            Text(
                              "Non analysé",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Image
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.memory(
                            base64Decode(lastPhoto),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    
                    // Footer
                    Container(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _recognizeSignFromCamera();
                            },
                            icon: const Icon(Icons.camera_alt, color: Colors.white),
                            label: const Text("Nouvelle photo", style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryRed,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: const Text("Fermer", style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Aucune photo capturée pour le moment"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'affichage: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug pour voir l'état des variables
    print('🔍 BUILD DEBUG:');
    print('🔍 showCapturedImage: $showCapturedImage');
    print('🔍 isCameraAvailable: $isCameraAvailable');
    print('🔍 isCameraInitialized: $isCameraInitialized');
    print('🔍 cameraController != null: ${cameraController != null}');
    print('🔍 capturedImagePath != null: ${capturedImagePath != null}');
    
    return Scaffold(
      backgroundColor: const Color(0xFF1a2332),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 30),

              // ZONE DE CAMÉRA - CAMÉRA RÉELLE
              Container(
                width: double.infinity,
                height: 400,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  color: const Color(0xFF2a3a52),
                ),
                child: Stack(
                  children: [
                    // AFFICHAGE DE LA CAMÉRA RÉELLE (par défaut)
                    if (isCameraAvailable && isCameraInitialized && cameraController != null)
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
                      
                      // AFFICHAGE DE L'IMAGE CAPTURÉE (par-dessus la caméra)
                      if (showCapturedImage && capturedImagePath != null)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              color: Colors.black.withOpacity(0.9),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Image.memory(
                                        base64Decode(capturedImagePath!),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // BOUTONS D'ACTION APRÈS CAPTURE
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      // BOUTON REPRENDRE
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            showCapturedImage = false;
                                            capturedImagePath = null;
                                            detectedSign = null;
                                            detectedWord = null;
                                            confidence = null;
                                          });
                                        },
                                        icon: const Icon(Icons.refresh, color: Colors.white),
                                        label: const Text("Reprendre", style: TextStyle(color: Colors.white)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                        ),
                                      ),
                                      
                                      // BOUTON ANALYSER
                                      ElevatedButton.icon(
                                        onPressed: _analyzeCapturedImage,
                                        icon: const Icon(Icons.analytics, color: Colors.white),
                                        label: const Text("Analyser", style: TextStyle(color: Colors.white)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryRed,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    
                    // MESSAGE SI CAMÉRA NON DISPONIBLE
                    if (!isCameraAvailable)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 80,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              "Caméra non disponible",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Vérifiez que votre caméra est connectée\net autorisée dans le navigateur",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // MESSAGE D'INITIALISATION
                    if (isCameraAvailable && !isCameraInitialized)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                primaryRed,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Initialisation de la caméra...",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // OVERLAY PENDANT L'ANALYSE
                    if (isLoading && showCapturedImage)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: Colors.black.withOpacity(0.7),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  primaryRed,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "Analyse en cours...",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // RÉSULTAT DE DÉTECTION
                    if (detectedSign != null && !isLoading)
                      Positioned(
                        top: 20,
                        left: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: primaryRed.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Signe détecté: ${detectedSign!}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // RÉSULTATS DE LA RECONNAISSANCE
              if (detectedSign != null && !isLoading)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Résultats",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // SIGNE DÉTECTÉ
                      _buildResultRow(
                        label: "Signe:",
                        value: detectedSign!,
                        color: primaryRed,
                      ),
                      const SizedBox(height: 15),

                      // MOT EN FRANÇAIS
                      _buildResultRow(
                        label: "Mot:",
                        value: detectedWord ?? "N/A",
                        color: Colors.white,
                      ),
                      const SizedBox(height: 15),

                      // CONFIANCE
                      _buildConfidenceBar(confidence ?? 0.0),
                    ],
                  ),
                ),
              const SizedBox(height: 40),

              // MESSAGE D'INFO
              if (!isCameraAvailable)
                Text(
                  "Caméra non détectée. Vérifiez que votre caméra\nest connectée et autorisée dans le navigateur.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              if (isCameraAvailable && !isCameraInitialized)
                Text(
                  "Initialisation de la caméra en cours...",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              if (isCameraAvailable && isCameraInitialized)
                Text(
                  "Caméra prête. Cliquez sur le bouton pour\ncapturer et analyser un signe.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              const SizedBox(height: 40),

              // BOUTON D'ACTION
              if (!showCapturedImage)
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: (isLoading || !isCameraAvailable || !isCameraInitialized) 
                        ? null 
                        : _recognizeSignFromCamera,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRed,
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isCameraAvailable ? Icons.camera_alt : Icons.camera_alt_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isCameraAvailable 
                              ? "Capturer et analyser"
                              : "Caméra non disponible",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (!showCapturedImage) const SizedBox(height: 20),

              // 🆕 BOUTON DÉTECTION TEMPS RÉEL (désactivé - page inexistante)
              // if (!showCapturedImage)
              //   SizedBox(
              //     width: double.infinity,
              //     height: 50,
              //     child: ElevatedButton.icon(
              //       onPressed: () {
              //         Navigator.push(
              //           context,
              //           MaterialPageRoute(
              //             builder: (context) => const AILiveDetectionPage(),
              //           ),
              //         );
              //       },
              //       icon: const Icon(Icons.live_tv, color: Colors.white),
              //       label: const Text("Détection temps réel", style: TextStyle(color: Colors.white)),
              //       style: ElevatedButton.styleFrom(
              //         backgroundColor: Colors.green,
              //         shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(50),
              //         ),
              //       ),
              //     ),
              //   ),

              if (!showCapturedImage) const SizedBox(height: 20),

              // BOUTON POUR VOIR LA DERNIÈRE PHOTO
              if (!showCapturedImage)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _viewLastCapturedPhoto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      elevation: 0,
                    ),
                    icon: Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white.withOpacity(0.8),
                      size: 20,
                    ),
                    label: Text(
                      "Voir la dernière photo",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceBar(double confidence) {
    final percentage = (confidence * 100).toStringAsFixed(0);
    final color = confidence > 0.8
        ? Colors.green
        : confidence > 0.6
            ? Colors.yellow
            : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Confiance:",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            Text(
              "$percentage%",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: confidence,
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
