import 'dart:convert';
import 'dart:io';

// Service d'authentification backend simple pour les tests
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Base de données utilisateurs simulée (en mémoire)
  final Map<String, Map<String, dynamic>> _users = {};

  // Simuler une connexion HTTP
  Future<Map<String, dynamic>> _simulateHttpRequest(String method, String endpoint, Map<String, dynamic>? data) async {
    // Simuler un délai réseau
    await Future.delayed(Duration(milliseconds: 800 + (DateTime.now().millisecond % 500)));

    switch (endpoint) {
      case '/login':
        return _handleLogin(data!);
      case '/register':
        return _handleRegister(data!);
      case '/profile':
        return _handleProfile(data!['email']);
      default:
        throw Exception('Endpoint not found: $endpoint');
    }
  }

  // Gérer la connexion
  Map<String, dynamic> _handleLogin(Map<String, dynamic> data) {
    final email = data['email'] as String;
    final password = data['password'] as String;

    final user = _users[email];
    
    if (user == null) {
      return {
        'success': false,
        'message': 'Utilisateur non trouvé',
        'error': 'USER_NOT_FOUND',
      };
    }

    if (user['password'] != password) {
      return {
        'success': false,
        'message': 'Mot de passe incorrect',
        'error': 'INVALID_PASSWORD',
      };
    }

    // Retourner les infos utilisateur (sans le mot de passe)
    final userResponse = Map<String, dynamic>.from(user);
    userResponse.remove('password');
    
    return {
      'success': true,
      'message': 'Connexion réussie',
      'user': userResponse,
      'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  // Gérer l'inscription
  Map<String, dynamic> _handleRegister(Map<String, dynamic> data) {
    final email = data['email'] as String;
    final password = data['password'] as String;
    final name = data['name'] as String;

    // Vérifier si l'utilisateur existe déjà
    if (_users.containsKey(email)) {
      return {
        'success': false,
        'message': 'Cet email est déjà utilisé',
        'error': 'EMAIL_ALREADY_EXISTS',
      };
    }

    // Créer le nouvel utilisateur
    final newUser = {
      'id': (_users.length + 1).toString(),
      'email': email,
      'password': password,
      'name': name,
      'createdAt': DateTime.now().toIso8601String().split('T')[0],
      'xp': 0,
      'level': 'Débutant',
    };

    _users[email] = newUser;

    // Retourner les infos utilisateur (sans le mot de passe)
    final userResponse = Map<String, dynamic>.from(newUser);
    userResponse.remove('password');

    return {
      'success': true,
      'message': 'Inscription réussie',
      'user': userResponse,
      'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  // Gérer la récupération du profil
  Map<String, dynamic> _handleProfile(String email) {
    final user = _users[email];
    
    if (user == null) {
      return {
        'success': false,
        'message': 'Utilisateur non trouvé',
        'error': 'USER_NOT_FOUND',
      };
    }

    // Retourner les infos utilisateur (sans le mot de passe)
    final userResponse = Map<String, dynamic>.from(user);
    userResponse.remove('password');

    return {
      'success': true,
      'user': userResponse,
    };
  }

  // Méthodes publiques pour l'application
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _simulateHttpRequest('POST', '/login', {
        'email': email,
        'password': password,
      });
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
        'error': 'NETWORK_ERROR',
      };
    }
  }

  Future<Map<String, dynamic>> register(String email, String password, String name) async {
    try {
      final response = await _simulateHttpRequest('POST', '/register', {
        'email': email,
        'password': password,
        'name': name,
      });
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
        'error': 'NETWORK_ERROR',
      };
    }
  }

  Future<Map<String, dynamic>> getProfile(String email) async {
    try {
      final response = await _simulateHttpRequest('GET', '/profile', {
        'email': email,
      });
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
        'error': 'NETWORK_ERROR',
      };
    }
  }
}
