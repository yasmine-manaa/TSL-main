import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'backend_auth_service.dart';

class UserService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserPassword = 'user_password';
  static const String _keyUserXP = 'user_xp';
  static const String _keyUserLevel = 'user_level';
  static const String _keyUserId = 'user_id';

  final BackendAuthService _backendAuth = BackendAuthService();

  // Connexion utilisateur avec backend
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final backendAuth = BackendAuthService();
    
    final result = await backendAuth.login(email, password);
    
    if (result['success'] == true) {
      final user = result['user'];
      final token = result['token'];
      
      // Sauvegarder la session
      await backendAuth.saveSession(user, token);
      
      // Sauvegarder localement pour compatibilité
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUserName, user['name']);
      await prefs.setString(_keyUserEmail, user['email']);
      await prefs.setString(_keyUserId, user['id'].toString());
      await prefs.setInt(_keyUserXP, user['xp'] ?? 0);
      await prefs.setString(_keyUserLevel, user['level'] ?? 'Débutant');
    }
    
    return result;
  }

  // Inscription utilisateur avec backend
  static Future<Map<String, dynamic>> register(String email, String password, String name) async {
    final backendAuth = BackendAuthService();
    final result = await backendAuth.register(email, password, name);
    
    // Ne pas sauvegarder la session après inscription
    // L'utilisateur doit se connecter manuellement
    
    return result;
  }

  // Sauvegarder l'état de connexion (ancienne méthode pour compatibilité)
  static Future<void> saveLoginState({
    required String userName,
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserName, userName);
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyUserPassword, password);
  }

  // Vérifier si l'utilisateur est connecté
  static Future<bool> isLoggedIn() async {
    final backendAuth = BackendAuthService();
    final session = await backendAuth.getSession();
    
    if (session != null) {
      return true;
    }
    
    // Fallback sur l'ancienne méthode
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Obtenir les informations de l'utilisateur
  static Future<Map<String, String>> getUserInfo() async {
    final backendAuth = BackendAuthService();
    final session = await backendAuth.getSession();
    
    if (session != null) {
      return {
        'name': session['name'] ?? 'Utilisateur',
        'email': session['email'] ?? 'user@example.com',
        'password': '', // Ne pas stocker le mot de passe
      };
    }
    
    // Fallback sur l'ancienne méthode
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_keyUserName) ?? 'Ahmed Ben Ali',
      'email': prefs.getString(_keyUserEmail) ?? 'ahmed.benali@example.com',
      'password': prefs.getString(_keyUserPassword) ?? '',
    };
  }

  // Obtenir les données utilisateur complètes
  static Future<Map<String, dynamic>?> getUserData() async {
    final backendAuth = BackendAuthService();
    final session = await backendAuth.getSession();
    
    if (session != null) {
      return session;
    }
    
    // Fallback sur l'ancienne méthode
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyUserName);
    final email = prefs.getString(_keyUserEmail);
    if (name == null && email == null) return null;
    
    return {
      'name': name ?? '',
      'email': email ?? '',
      'xp': prefs.getInt(_keyUserXP) ?? 0,
      'level': prefs.getString(_keyUserLevel) ?? 'Débutant',
      'id': prefs.getString(_keyUserId) ?? '1',
    };
  }

  // Mettre à jour les informations de l'utilisateur
  static Future<void> updateUserInfo({
    String? userName,
    String? email,
    String? password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (userName != null) {
      await prefs.setString(_keyUserName, userName);
    }
    if (email != null) {
      await prefs.setString(_keyUserEmail, email);
    }
    if (password != null) {
      await prefs.setString(_keyUserPassword, password);
    }
  }

  // Sauvegarder les XP de l'utilisateur
  static Future<void> saveUserXP(int xp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserXP, xp);
  }

  // Ajouter des XP à un utilisateur
  static Future<Map<String, dynamic>> addXP(int xpToAdd) async {
    try {
      final backendAuth = BackendAuthService();
      final session = await backendAuth.getSession();
      
      if (session == null) {
        return {
          'success': false,
          'message': 'Utilisateur non connecté',
          'error': 'USER_NOT_LOGGED_IN',
        };
      }
      
      final email = session['email'] as String;
      final result = await backendAuth.addXP(email, xpToAdd);
      
      if (result['success'] == true) {
        // Mettre à jour les données locales
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_keyUserXP, result['total_xp']);
        await prefs.setString(_keyUserLevel, result['level']);
      }
      
      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur lors de l\'ajout des XP: ${e.toString()}',
        'error': 'XP_UPDATE_FAILED',
      };
    }
  }
  
  // Obtenir les statistiques de jeu
  static Future<Map<String, dynamic>> getGameStats() async {
    try {
      final backendAuth = BackendAuthService();
      final session = await backendAuth.getSession();
      
      if (session == null) {
        return {
          'success': false,
          'message': 'Utilisateur non connecté',
        };
      }
      
      final email = session['email'] as String;
      return await backendAuth.getGameStats(email);
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
      };
    }
  }

  // Se déconnecter
  static Future<void> logout() async {
    final backendAuth = BackendAuthService();
    await backendAuth.logout();
    
    // Nettoyer les données locales
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserPassword);
    await prefs.remove(_keyUserXP);
    await prefs.remove(_keyUserLevel);
    await prefs.remove(_keyUserId);
  }

  // Alias pour logout (compatibilité)
  static Future<void> clearUserData() async {
    await logout();
  }

  // Alias pour updateUserProfile (compatibilité)
  static Future<void> updateUserProfile({
    required String name,
    required String email,
  }) async {
    await updateUserInfo(userName: name, email: email);
  }

  // Mettre à jour le profil avec mot de passe
  static Future<Map<String, dynamic>> updateProfile(
    String email,
    String name,
    String currentPassword,
    String newPassword,
  ) async {
    final backendAuth = BackendAuthService();
    
    try {
      // Si un nouveau mot de passe est fourni, vérifier d'abord le mot de passe actuel
      if (newPassword.isNotEmpty) {
        final loginResult = await backendAuth.login(email, currentPassword);
        if (loginResult['success'] != true) {
          return {
            'success': false,
            'message': 'Mot de passe actuel incorrect',
          };
        }
      }
      
      // Mettre à jour le profil dans le backend
      final result = await backendAuth.updateProfile(
        email: email,
        name: name,
        password: newPassword.isNotEmpty ? newPassword : null,
      );
      
      if (result['success'] == true) {
        // Mettre à jour les informations locales
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUserName, name);
        
        return {
          'success': true,
          'message': 'Profil mis à jour avec succès',
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Erreur lors de la mise à jour',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
      };
    }
  }
}
