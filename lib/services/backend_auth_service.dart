import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'database_service.dart';
import 'firebase_auth_service_safe.dart';

// Service d'authentification qui communique avec le backend
class BackendAuthService {
  static final BackendAuthService _instance = BackendAuthService._internal();
  factory BackendAuthService() => _instance;
  BackendAuthService._internal();

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  
  final DatabaseService _database = DatabaseService();
  FirebaseAuthServiceSafe? _firebaseAuth;
  
  // Switch pour choisir entre Firebase et base locale
  static const bool _useFirebase = true;
  
  // Initialiser la base de données
  Future<void> initialize() async {
    if (_useFirebase) {
      _firebaseAuth = await FirebaseAuthServiceSafe.getInstance();
    } else {
      await _database.initializeDatabase();
    }
  }

  // Connexion utilisateur
  Future<Map<String, dynamic>> login(String email, String password) async {
    if (_useFirebase) {
      if (_firebaseAuth == null) {
        return {
          'success': false,
          'message': 'Firebase non initialisé',
          'error': 'FIREBASE_NOT_READY',
        };
      }
      return await _firebaseAuth!.login(email, password);
    } else {
      return await _database.login(email, password);
    }
  }

  // Inscription utilisateur
  Future<Map<String, dynamic>> register(String email, String password, String name) async {
    if (_useFirebase) {
      if (_firebaseAuth == null) {
        return {
          'success': false,
          'message': 'Firebase non initialisé',
          'error': 'FIREBASE_NOT_READY',
        };
      }
      return await _firebaseAuth!.register(email, password, name);
    } else {
      return await _database.register(email, password, name);
    }
  }

  // Récupérer le profil utilisateur
  Future<Map<String, dynamic>> getProfile(String email) async {
    if (_useFirebase) {
      if (_firebaseAuth == null) {
        return {
          'success': false,
          'message': 'Firebase non initialisé',
          'error': 'FIREBASE_NOT_READY',
        };
      }
      return await _firebaseAuth!.getProfile(email);
    } else {
      return await _database.getProfile(email);
    }
  }

  // Sauvegarder la session utilisateur
  Future<void> saveSession(Map<String, dynamic> user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user));
  }

  // Récupérer la session utilisateur
  Future<Map<String, dynamic>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    
    if (userJson != null) {
      return jsonDecode(userJson);
    }
    return null;
  }

  // Vérifier si l'utilisateur est connecté
  Future<bool> isLoggedIn() async {
    final session = await getSession();
    return session != null;
  }

  // Déconnexion
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // Ajouter des XP à un utilisateur
  Future<Map<String, dynamic>> addXP(String email, int xpToAdd) async {
    if (_useFirebase) {
      if (_firebaseAuth == null) {
        return {
          'success': false,
          'message': 'Firebase non initialisé',
          'error': 'FIREBASE_NOT_READY',
        };
      }
      return await _firebaseAuth!.addXP(email, xpToAdd);
    } else {
      return await _database.addXP(email, xpToAdd);
    }
  }

  // Obtenir les statistiques de jeu
  Future<Map<String, dynamic>> getGameStats(String email) async {
    if (_useFirebase) {
      if (_firebaseAuth == null) {
        return {
          'success': false,
          'message': 'Firebase non initialisé',
          'error': 'FIREBASE_NOT_READY',
        };
      }
      return await _firebaseAuth!.getGameStats(email);
    } else {
      return await _database.getGameStats(email);
    }
  }
  
  // Afficher les comptes de test disponibles
  void printTestAccounts() {
    if (_useFirebase) {
      _firebaseAuth?.printTestAccounts();
    } else {
      // _database.printTestAccounts();
    }
  }

  // Mettre à jour le profil utilisateur
  Future<Map<String, dynamic>> updateProfile({
    required String email,
    required String name,
    String? password,
  }) async {
    if (_useFirebase) {
      if (_firebaseAuth == null) {
        return {
          'success': false,
          'message': 'Firebase non initialisé',
          'error': 'FIREBASE_NOT_READY',
        };
      }
      return await _firebaseAuth!.updateProfile(email: email, name: name, password: password);
    } else {
      return await _database.updateProfile(email: email, name: name, password: password);
    }
  }
}
