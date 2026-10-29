import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class BackendAIService {
  static final BackendAIService _instance = BackendAIService._internal();
  factory BackendAIService() => _instance;
  BackendAIService._internal();

  /// Adresse du backend Flask utilisée actuellement.
  ///
  /// Par défaut :
  /// - Android émulateur : http://10.0.2.2:5000
  /// - iOS simulateur : http://localhost:5000
  /// - réel device Android/iOS : à configurer manuellement avec setBaseUrl
  String _baseUrl = _defaultBaseUrl();

  static String _defaultBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:5000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000';
    }
    if (Platform.isIOS || Platform.isMacOS) {
      return 'http://localhost:5000';
    }
    return 'http://localhost:5000';
  }

  String get baseUrl => _baseUrl;

  void setBaseUrl(String url) {
    _baseUrl = url;
  }

  /// Vérifie que le backend est accessible
  Future<bool> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health')).timeout(
        const Duration(seconds: 3),
        onTimeout: () => throw Exception('Timeout'),
      );
      if (response.statusCode != 200) {
        print('Backend health check failed ($_baseUrl): HTTP ${response.statusCode}');
      }
      return response.statusCode == 200;
    } catch (e) {
      print('Backend health check failed ($_baseUrl): $e');
      return false;
    }
  }

  /// Envoie une image (fichier) au backend pour détection
  /// Retourne le JSON du backend: {detected, sign, confidence, bbox, message}
  Future<Map<String, dynamic>> detectFromFile(File imageFile) async {
    try {
      final uri = Uri.parse('$_baseUrl/detect');
      final request = http.MultipartRequest('POST', uri);

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Timeout lors de l\'envoi de l\'image'),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('Backend error $_baseUrl ${response.statusCode}: ${response.body}');
        throw Exception('Erreur backend ($_baseUrl): ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur detectFromFile ($_baseUrl): $e');
      rethrow;
    }
  }

  /// Envoie des bytes d'image (Uint8List) au backend pour détection
  /// Utile pour envoyer directement depuis CameraImage ou memory
  Future<Map<String, dynamic>> detectFromBytes(Uint8List imageBytes, {String filename = 'capture.jpg'}) async {
    try {
      final uri = Uri.parse('$_baseUrl/detect');
      final request = http.MultipartRequest('POST', uri);

      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: filename,
        contentType: MediaType('image', 'jpeg'),
      ));

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Timeout lors de l\'envoi de l\'image'),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('Backend error $_baseUrl ${response.statusCode}: ${response.body}');
        throw Exception('Erreur backend ($_baseUrl): ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur detectFromBytes ($_baseUrl): $e');
      rethrow;
    }
  }

  /// Envoie une image encodée en base64 (alternative si multipart pose problème)
  Future<Map<String, dynamic>> detectFromBase64(String base64Image) async {
    try {
      final uri = Uri.parse('$_baseUrl/detect_base64');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image_base64': base64Image}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('Backend error $_baseUrl ${response.statusCode}: ${response.body}');
        throw Exception('Erreur backend ($_baseUrl): ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur detectFromBase64 ($_baseUrl): $e');
      rethrow;
    }
  }
}
