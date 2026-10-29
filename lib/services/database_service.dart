import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Service de base de données locale pour les utilisateurs
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String _usersKey = 'users_database';
  
  // Base de données utilisateurs persistente
  Map<String, Map<String, dynamic>> _users = {};

  // Initialiser la base de données avec les comptes de test
  Future<void> initializeDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    
    if (usersJson != null) {
      try {
        final usersData = jsonDecode(usersJson) as Map<String, dynamic>;
        _users = usersData.map((key, value) => 
          MapEntry(key, Map<String, dynamic>.from(value))
        );
        print('📊 Base de données chargée: ${_users.length} utilisateurs');
      } catch (e) {
        print('❌ Erreur de chargement: $e');
      }
    } else {
      print('📝 Aucune base de données trouvée, création...');
    }
  }
  
  // Sauvegarder les utilisateurs dans SharedPreferences
  Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(_users));
    print('💾 Base de données sauvegardée: ${_users.length} utilisateurs');
  }

  // Connexion utilisateur
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      await Future.delayed(Duration(milliseconds: 800));

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
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: ${e.toString()}',
        'error': 'LOGIN_FAILED',
      };
    }
  }

  // Inscription utilisateur
  Future<Map<String, dynamic>> register(String email, String password, String name) async {
    try {
      await Future.delayed(Duration(milliseconds: 1000));

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
        'games_played': 0,
        'last_game_score': 0,
      };
      
      _users[email] = newUser;
      await _saveUsers();
      print('✅ Nouvel utilisateur inscrit: $email');
      print('📊 Total utilisateurs: ${_users.length}');

      // Retourner les infos utilisateur (sans le mot de passe)
      final userResponse = Map<String, dynamic>.from(newUser);
      userResponse.remove('password');

      return {
        'success': true,
        'message': 'Inscription réussie',
        'user': userResponse,
        'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur d\'inscription: ${e.toString()}',
        'error': 'REGISTRATION_FAILED',
      };
    }
  }

  // Récupérer le profil utilisateur
  Future<Map<String, dynamic>> getProfile(String email) async {
    try {
      await Future.delayed(Duration(milliseconds: 500));

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
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
        'error': 'PROFILE_FAILED',
      };
    }
  }

  // Ajouter des XP à un utilisateur
  Future<Map<String, dynamic>> addXP(String email, int xpToAdd) async {
    try {
      await Future.delayed(Duration(milliseconds: 300));
      
      final user = _users[email];
      if (user == null) {
        return {
          'success': false,
          'message': 'Utilisateur non trouvé',
          'error': 'USER_NOT_FOUND',
        };
      }
      
      // Mettre à jour les XP
      final currentXP = user['xp'] as int;
      final newXP = currentXP + xpToAdd;
      user['xp'] = newXP;
      user['games_played'] = (user['games_played'] as int) + 1;
      user['last_game_score'] = xpToAdd;
      
      // Mettre à jour le niveau selon les XP
      user['level'] = _calculateLevel(newXP);
      
      // Sauvegarder les modifications
      await _saveUsers();
      
      // Retourner les infos utilisateur (sans le mot de passe)
      final userResponse = Map<String, dynamic>.from(user);
      userResponse.remove('password');
      
      return {
        'success': true,
        'message': 'XP ajoutés avec succès',
        'xp_added': xpToAdd,
        'total_xp': newXP,
        'level': user['level'],
        'user': userResponse,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur lors de l\'ajout des XP: ${e.toString()}',
        'error': 'XP_UPDATE_FAILED',
      };
    }
  }
  
  // Calculer le niveau selon les XP
  String _calculateLevel(int xp) {
    if (xp < 100) return 'Débutant';
    if (xp < 300) return 'Intermédiaire';
    if (xp < 600) return 'Avancé';
    if (xp < 1000) return 'Expert';
    return 'Maître';
  }
  
  // Obtenir les statistiques de jeu
  Future<Map<String, dynamic>> getGameStats(String email) async {
    try {
      final user = _users[email];
      if (user == null) {
        return {
          'success': false,
          'message': 'Utilisateur non trouvé',
        };
      }
      
      return {
        'success': true,
        'stats': {
          'total_xp': user['xp'],
          'level': user['level'],
          'games_played': user['games_played'],
          'last_game_score': user['last_game_score'],
          'avg_score': user['games_played'] > 0 
            ? (user['xp'] as int) / (user['games_played'] as int)
            : 0,
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
      };
    }
  }

  // Mettre à jour le profil utilisateur
  Future<Map<String, dynamic>> updateProfile({
    required String email,
    required String name,
    String? password,
  }) async {
    try {
      Map<String, dynamic>? user;
      
      // Chercher l'utilisateur dans la liste des utilisateurs
      for (var userEmail in _users.keys) {
        if (userEmail == email) {
          user = _users[userEmail];
          break;
        }
      }
      
      if (user != null) {
        // Mettre à jour le nom
        user['name'] = name;
        
        // Si un nouveau mot de passe est fourni, le mettre à jour
        if (password != null && password.isNotEmpty) {
          user['password'] = password;
        }
        
        return {
          'success': true,
          'message': 'Profil mis à jour avec succès',
        };
      } else {
        return {
          'success': false,
          'message': 'Utilisateur non trouvé',
          'error': 'USER_NOT_FOUND',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur lors de la mise à jour du profil: ${e.toString()}',
        'error': 'UPDATE_FAILED',
      };
    }
  }
}
