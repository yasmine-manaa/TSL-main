import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Service d'authentification Firebase sécurisé
class FirebaseAuthServiceSafe {
  static FirebaseAuthServiceSafe? _instance;
  static bool _isInitialized = false;
  static bool _isInitializing = false;
  
  // Instance différées - initialisées seulement après Firebase.initializeApp()
  late FirebaseAuth _auth;
  late FirebaseFirestore _firestore;
  
  static const String _userKey = 'user_data';

  // Factory pattern avec initialisation sécurisée
  static Future<FirebaseAuthServiceSafe> getInstance() async {
    if (_instance == null) {
      _instance = FirebaseAuthServiceSafe._internal();
      await _instance!._initialize();
    }
    return _instance!;
  }
  
  // Constructeur privé
  FirebaseAuthServiceSafe._internal();
  
  // Initialisation sécurisée de Firebase
  Future<void> _initialize() async {
    if (_isInitialized || _isInitializing) return;
    
    _isInitializing = true;
    
    try {
      // Initialiser Firebase (Android/iOS lisent google-services.json automatiquement)
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      
      // Maintenant on peut initialiser les instances Firebase
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      
      _isInitialized = true;
      
      if (kDebugMode) {
        print('🔥 Firebase initialisé avec succès');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur d\'initialisation Firebase: $e');
      }
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }
  
  // Vérifier si Firebase est prêt
  bool get isInitialized => _isInitialized;

  // Connexion utilisateur
  Future<Map<String, dynamic>> login(String email, String password) async {
    if (!_isInitialized) {
      return {
        'success': false,
        'message': 'Firebase non initialisé',
        'error': 'FIREBASE_NOT_READY',
      };
    }
    
    try {
      await Future.delayed(Duration(milliseconds: 800));

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Créer des données utilisateur basiques depuis Firebase Auth
      // (Temporaire : éviter l'accès Firestore jusqu'à ce que les règles soient déployées)
      final user = userCredential.user!;
      final basicUserData = {
        'id': user.uid,
        'email': user.email ?? email,
        'name': user.displayName ?? email.split('@')[0], // Utiliser le nom d'utilisateur de l'email
        'xp': 0,
        'level': 'Débutant',
        'created_at': DateTime.now().toIso8601String(),
      };

      // Nettoyer les données (même si basiques)
      final cleanData = _sanitizeFirebaseData(basicUserData);

      // Sauvegarder la session localement
      final token = await user.getIdToken() ?? '';
      await saveSession(cleanData, token);

      return {
        'success': true,
        'message': 'Connexion réussie',
        'user': cleanData,
        'token': token,
      };

      /* CODE COMMENTÉ TEMPORAIREMENT - À RÉACTIVER APRÈS DÉPLOIEMENT DES RÈGLES FIRESTORE
      // Récupérer les données utilisateur depuis Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;

        // Nettoyer les données Firebase avant de les sauvegarder
        final cleanData = _sanitizeFirebaseData(userData);

        // Sauvegarder la session localement
        final token = await userCredential.user!.getIdToken() ?? '';
        await saveSession(cleanData, token);

        return {
          'success': true,
          'message': 'Connexion réussie',
          'user': cleanData,
          'token': token,
        };
      } else {
        return {
          'success': false,
          'message': 'Utilisateur non trouvé dans la base de données',
          'error': 'USER_NOT_FOUND',
        };
      }
      */
    } on FirebaseAuthException catch (e) {
      String message = 'Erreur de connexion';
      if (e.code == 'user-not-found') {
        message = 'Utilisateur non trouvé';
      } else if (e.code == 'wrong-password') {
        message = 'Mot de passe incorrect';
      } else if (e.code == 'invalid-email') {
        message = 'Email invalide';
      }
      
      return {
        'success': false,
        'message': message,
        'error': e.code,
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
    if (!_isInitialized) {
      return {
        'success': false,
        'message': 'Firebase non initialisé',
        'error': 'FIREBASE_NOT_READY',
      };
    }
    
    try {
      await Future.delayed(Duration(milliseconds: 1000));

      // Logging du projet Firebase actuel
      if (kDebugMode) {
        final app = Firebase.app();
        print('🔥 Firebase project: ${app.options.projectId}');
        print('🔥 Firebase API key: ${app.options.apiKey}');
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userData = {
        'email': email,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
        'xp': 0,
        'level': 'Débutant',
        'games_played': 0,
        'last_game_score': 0,
      };

      try {
        await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);
        print('✅ Données utilisateur sauvegardées dans Firestore');
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          print('⚠️ Firestore permission-denied lors inscription, continuation avec données locales seulement');
        } else {
          print('⚠️ Erreur Firestore lors inscription: ${e.code} - ${e.message}');
        }
      } catch (e) {
        print('⚠️ Erreur inattendue Firestore: $e');
      }

      // Nettoyer les données avant de les sauvegarder
      final cleanData = _sanitizeFirebaseData(userData);

      // Sauvegarder la session localement
      final token = await userCredential.user!.getIdToken() ?? '';
      await saveSession(cleanData, token);

      return {
        'success': true,
        'message': 'Inscription réussie',
        'user': cleanData,
        'token': token,
      };
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('❌ FirebaseAuthException [${e.code}]: ${e.message}');
      }

      // Si l'email existe déjà, tenter de se connecter automatiquement
      if (e.code == 'email-already-in-use') {
        print('⚠️ Email déjà utilisé, tentative de connexion automatique...');
        try {
          final loginResult = await login(email, password);
          if (loginResult['success'] == true) {
            print('✅ Connexion automatique réussie (compte existant)');
            return {
              'success': true,
              'message': 'Connexion réussie (compte existant)',
              'user': loginResult['user'],
              'token': loginResult['token'],
            };
          } else {
            print('❌ Connexion automatique échouée: ${loginResult['message']}');
            return {
              'success': false,
              'message': 'Cet email est déjà utilisé. ${loginResult['message']}',
              'error': e.code,
            };
          }
        } catch (loginError) {
          print('❌ Connexion automatique erreur: $loginError');
          return {
            'success': false,
            'message': 'Cet email est déjà utilisé. Mot de passe incorrect ?',
            'error': e.code,
          };
        }
      }

      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'Le mot de passe est trop faible (min 6 caractères)';
          break;
        case 'invalid-email':
          message = 'Email invalide';
          break;
        case 'network-request-failed':
          message = 'Pas de connexion Internet. Vérifiez votre réseau.';
          break;
        case 'too-many-requests':
          message = 'Trop de tentatives. Réessayez plus tard.';
          break;
        case 'operation-not-allowed':
          message = 'L\'inscription par email est désactivée dans Firebase Console.';
          break;
        case 'invalid-credential':
          message = 'Identifiants invalides.';
          break;
        case 'internal-error':
          message = 'Erreur interne Firebase. Réessayez.';
          break;
        case 'user-disabled':
          message = 'Ce compte a été désactivé.';
          break;
        default:
          message = 'Erreur Firebase [${e.code}]: ${e.message ?? ""}';
      }
      
      return {
        'success': false,
        'message': message,
        'error': e.code,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur inscription générale: $e');
      }
      // Pour les erreurs générales (comme Firestore permission-denied), continuer quand même
      // car l'utilisateur Firebase Auth a été créé avec succès
      if (e.toString().contains('permission-denied')) {
        print('⚠️ Erreur Firestore permission-denied détectée, mais inscription Firebase Auth réussie');
        // Retourner succès car l'utilisateur est quand même créé
        return {
          'success': true,
          'message': 'Inscription réussie (sans sauvegarde Firestore)',
          'user': {
            'id': 'unknown', // On ne peut pas récupérer l'UID sans userCredential
            'email': email,
            'name': name,
            'xp': 0,
            'level': 'Débutant',
          },
          'token': '',
        };
      }

      return {
        'success': false,
        'message': 'Erreur d\'inscription: ${e.toString()}',
        'error': 'REGISTRATION_FAILED',
      };
    }
  }

  // Récupérer le profil utilisateur
  Future<Map<String, dynamic>> getProfile(String email) async {
    if (!_isInitialized) {
      return {
        'success': false,
        'message': 'Firebase non initialisé',
        'error': 'FIREBASE_NOT_READY',
      };
    }
    
    try {
      await Future.delayed(Duration(milliseconds: 500));
      
      final userDoc = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      
      if (userDoc.docs.isNotEmpty) {
        final userData = userDoc.docs.first.data()!;
        final cleanData = _sanitizeFirebaseData(userData);
        return {
          'success': true,
          'user': cleanData,
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
        'message': 'Erreur: ${e.toString()}',
        'error': 'PROFILE_FAILED',
      };
    }
  }

  // Ajouter des XP à un utilisateur
  Future<Map<String, dynamic>> addXP(String email, int xpToAdd) async {
    if (!_isInitialized) {
      return {
        'success': false,
        'message': 'Firebase non initialisé',
        'error': 'FIREBASE_NOT_READY',
      };
    }
    
    try {
      await Future.delayed(Duration(milliseconds: 300));
      
      final userDoc = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      
      if (userDoc.docs.isEmpty) {
        return {
          'success': false,
          'message': 'Utilisateur non trouvé',
          'error': 'USER_NOT_FOUND',
        };
      }
      
      final userId = userDoc.docs.first.id;
      final currentData = userDoc.docs.first.data()!;
      
      final currentXP = currentData['xp'] as int;
      final newXP = currentXP + xpToAdd;
      final newLevel = _calculateLevel(newXP);
      
      await _firestore.collection('users').doc(userId).update({
        'xp': newXP,
        'level': newLevel,
        'games_played': (currentData['games_played'] as int) + 1,
        'last_game_score': xpToAdd,
      });
      
      final updatedDoc = await _firestore.collection('users').doc(userId).get();
      final updatedData = updatedDoc.data()!;
      
      // Nettoyer les données avant de les sauvegarder et retourner
      final cleanData = _sanitizeFirebaseData(updatedData);
      await saveSession(cleanData, await _auth.currentUser?.getIdToken() ?? '');
      
      return {
        'success': true,
        'message': 'XP ajoutés avec succès',
        'xp_added': xpToAdd,
        'total_xp': newXP,
        'level': newLevel,
        'user': cleanData,
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
    if (!_isInitialized) {
      return {
        'success': false,
        'message': 'Firebase non initialisé',
        'error': 'FIREBASE_NOT_READY',
      };
    }
    
    try {
      final userDoc = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      
      if (userDoc.docs.isNotEmpty) {
        final userData = userDoc.docs.first.data()!;
        final cleanData = _sanitizeFirebaseData(userData);
        return {
          'success': true,
          'stats': {
            'total_xp': cleanData['xp'],
            'level': cleanData['level'],
            'games_played': cleanData['games_played'],
            'last_game_score': cleanData['last_game_score'],
            'avg_score': cleanData['games_played'] > 0 
              ? (cleanData['xp'] as int) / (cleanData['games_played'] as int)
              : 0,
          },
        };
      } else {
        return {
          'success': false,
          'message': 'Utilisateur non trouvé',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
      };
    }
  }

  // Transformer les objets Firebase en types simples pour JSON
  Map<String, dynamic> _sanitizeFirebaseData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};
    data.forEach((key, value) {
      if (value is FieldValue) {
        // Ignorer les objets FieldValue
        return;
      } else if (value is Timestamp) {
        // Transformer Timestamp en String ISO 8601
        sanitized[key] = value.toDate().toIso8601String();
      } else if (value is Map<String, dynamic>) {
        // Récursivement nettoyer les objets imbriqués
        sanitized[key] = _sanitizeFirebaseData(value);
      } else if (value is List) {
        // Nettoyer les listes
        sanitized[key] = value.map((item) {
          if (item is Timestamp) {
            return item.toDate().toIso8601String();
          } else if (item is Map<String, dynamic>) {
            return _sanitizeFirebaseData(item);
          }
          return item;
        }).toList();
      } else {
        // Garder les autres valeurs telles quelles
        sanitized[key] = value;
      }
    });
    return sanitized;
  }

  // Sauvegarder la session utilisateur
  Future<void> saveSession(Map<String, dynamic> user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Nettoyer les données Firebase avant de les sauvegarder
    final safeUser = _sanitizeFirebaseData(user);
    
    await prefs.setString(_userKey, jsonEncode(safeUser));
    await prefs.setString('auth_token', token);
  }

  // Récupérer la session utilisateur
  Future<Map<String, dynamic>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    
    if (userJson != null) {
      try {
        final user = jsonDecode(userJson) as Map<String, dynamic>;
        return user;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Vérifier si l'utilisateur est connecté
  Future<bool> isLoggedIn() async {
    final session = await getSession();
    return session != null && _auth.currentUser != null;
  }

  // Déconnexion
  Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove('auth_token');
  }

  // Mettre à jour le profil utilisateur
  Future<Map<String, dynamic>> updateProfile({
    required String email,
    required String name,
    String? password,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(email).get();
      
      if (userDoc.exists) {
        final updateData = <String, dynamic>{
          'name': name,
          'updated_at': FieldValue.serverTimestamp(),
        };
        
        // Si un nouveau mot de passe est fourni, le mettre à jour
        if (password != null && password.isNotEmpty) {
          final currentUser = _auth.currentUser;
          if (currentUser != null && currentUser.email == email) {
            await currentUser.updatePassword(password);
            updateData['password'] = password; // Pour la cohérence dans Firestore
          }
        }
        
        await _firestore.collection('users').doc(email).update(updateData);
        
        // Mettre à jour la session locale
        final session = await getSession();
        if (session != null) {
          final updatedSession = Map<String, dynamic>.from(session);
          updatedSession['name'] = name;
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token') ?? '';
          await saveSession(updatedSession, token);
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
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': 'Erreur lors de la mise à jour du profil: ${e.message}',
        'error': e.code,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur lors de la mise à jour du profil: ${e.toString()}',
        'error': 'UPDATE_FAILED',
      };
    }
  }

  // Afficher les comptes de test disponibles (désactivé pour éviter le spam)
  void printTestAccounts() {
    // Plus d'affichage pour éviter le spam dans le terminal
  }
}
