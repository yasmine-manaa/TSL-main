import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class FirebaseCommunityService {
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static FirebaseAuth get _auth => FirebaseAuth.instance;

  // Récupérer tous les utilisateurs réels depuis Firebase
  static Future<List<Map<String, dynamic>>> getRealUsers() async {
    try {
      final QuerySnapshot usersSnapshot = await _firestore
          .collection('users')
          .where('email', isNotEqualTo: null)
          .get();

      List<Map<String, dynamic>> realUsers = [];
      
      for (var doc in usersSnapshot.docs) {
        final userData = doc.data() as Map<String, dynamic>;
        
        // Calculer l'XP basé sur les statistiques de l'utilisateur
        final totalGames = userData['total_games'] ?? 0;
        final avgScore = userData['avg_score'] ?? 0.0;
        final lastGameScore = userData['last_game_score'] ?? 0;
        
        // Calculer l'XP : base de 10 XP par partie + bonus basés sur les scores
        num calculatedXP = totalGames * 10;
        calculatedXP += avgScore * 5; // Bonus pour score moyen
        calculatedXP += lastGameScore * 2; // Bonus pour dernier score
        calculatedXP = calculatedXP.toInt();
        
        // Ajouter de la variabilité pour rendre plus réaliste
        final random = Random();
        calculatedXP += random.nextInt(200) - 50; // Variation de -50 à +150
        
        // Déterminer le niveau et la ligue
        final level = _getLevelFromXP(calculatedXP.toInt());
        final league = _getLeagueFromXP(calculatedXP.toInt());
        
        // Créer l'avatar à partir du nom
        final name = userData['name'] ?? 'Utilisateur';
        final avatar = name.isNotEmpty ? name[0].toUpperCase() : 'U';
        
        // Statut en ligne aléatoire
        final isOnline = random.nextBool();
        
        // Progression hebdomadaire aléatoire
        final weeklyProgress = random.nextInt(10) - 3; // -3 à +6
        
        // Badges basés sur les performances
        List<String> badges = [];
        if (totalGames > 100) badges.add('Joueur Actif');
        if (avgScore > 70) badges.add('Excellent');
        if (lastGameScore > 80) badges.add('Performer');
        if (calculatedXP > 2000) badges.add('Expert');
        
        realUsers.add({
          'uid': doc.id,
          'name': name,
          'email': userData['email'] ?? '',
          'xp': calculatedXP,
          'level': level,
          'league': league,
          'avatar': avatar,
          'country': userData['country'] ?? 'Tunisie',
          'joinDate': userData['created_at'] ?? '2024-01-01',
          'totalGames': totalGames,
          'avgScore': avgScore,
          'lastGameScore': lastGameScore,
          'winRate': avgScore > 0 ? (avgScore / 100 * 100).roundToDouble() : 0.0,
          'streak': userData['streak'] ?? random.nextInt(15),
          'weeklyProgress': weeklyProgress,
          'isOnline': isOnline,
          'status': _getUserStatus(level, totalGames, avgScore),
          'badges': badges,
          'lastActive': userData['last_active'] ?? DateTime.now().toIso8601String(),
        });
      }
      
      return realUsers;
    } catch (e) {
      print('Erreur lors de la récupération des utilisateurs: $e');
      // En cas d'erreur, retourner une liste vide ou des données par défaut
      return [];
    }
  }

  // Récupérer le classement des utilisateurs réels
  static Future<List<Map<String, dynamic>>> getRealLeaderboard() async {
    try {
      final realUsers = await getRealUsers();
      
      // Ajouter l'utilisateur actuel s'il n'est pas dans la liste
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final prefs = await SharedPreferences.getInstance();
        final userXP = prefs.getInt('user_total_xp') ?? 0;
        final userName = prefs.getString('user_name') ?? currentUser.email?.split('@')[0] ?? 'Utilisateur';
        
        // Vérifier si l'utilisateur actuel est déjà dans la liste
        if (!realUsers.any((user) => user['uid'] == currentUser.uid)) {
          final random = Random();
          final totalGames = prefs.getInt('total_games') ?? 0;
          final avgScore = prefs.getDouble('avg_score') ?? 0.0;
          
          realUsers.add({
            'uid': currentUser.uid,
            'name': userName,
            'email': currentUser.email ?? '',
            'xp': userXP,
            'level': _getLevelFromXP(userXP),
            'league': _getLeagueFromXP(userXP),
            'avatar': userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
            'country': 'Tunisie',
            'joinDate': '2024-05-15',
            'totalGames': totalGames,
            'avgScore': avgScore,
            'lastGameScore': prefs.getInt('last_game_score') ?? 0,
            'winRate': avgScore > 0 ? (avgScore / 100 * 100).roundToDouble() : 0.0,
            'streak': prefs.getInt('current_streak') ?? 1,
            'weeklyProgress': random.nextInt(8) - 2,
            'isOnline': true,
            'status': 'Joueur actif',
            'badges': ['Active Player'],
            'lastActive': DateTime.now().toIso8601String(),
            'isCurrentUser': true,
          });
        }
      }
      
      // Trier par XP décroissant
      realUsers.sort((a, b) => (b['xp'] as int).compareTo(a['xp'] as int));
      
      // Assigner les rangs et les changements hebdomadaires
      for (int i = 0; i < realUsers.length; i++) {
        realUsers[i]['rank'] = i + 1;
        realUsers[i]['badge'] = _getRankBadge(i + 1);
        realUsers[i]['weeklyChange'] = _getWeeklyChange(i);
      }
      
      return realUsers;
    } catch (e) {
      print('Erreur lors de la récupération du classement: $e');
      return [];
    }
  }

  // Récupérer les amis de l'utilisateur actuel
  static Future<List<Map<String, dynamic>>> getUserFriends() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final friendsSnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('friends')
          .where('status', isEqualTo: 'accepted')
          .get();

      List<Map<String, dynamic>> friends = [];
      
      for (var friendDoc in friendsSnapshot.docs) {
        final friendData = friendDoc.data();
        final friendId = friendData['uid'] as String;
        
        // Récupérer les informations complètes de l'ami
        final userDoc = await _firestore.collection('users').doc(friendId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final profileImage = userData['profileImage'] as String?;
          final hasProfileImage = profileImage != null && profileImage.isNotEmpty;
          
          friends.add({
            'uid': friendId,
            'name': userData['name'] ?? 'Ami',
            'email': userData['email'] ?? '',
            'xp': userData['xp'] ?? 0,
            'level': _calculateLevel(userData['xp'] ?? 0),
            'avatar': userData['name']?.toString().isNotEmpty == true 
                ? userData['name']![0].toUpperCase()
                : 'A',
            'profileImage': profileImage,
            'hasProfileImage': hasProfileImage,
            'isOnline': _isUserOnline(friendId),
            'addedAt': friendData['addedAt'],
          });
        }
      }

      return friends;
    } catch (e) {
      print('Erreur lors de la récupération des amis: $e');
      return [];
    }
  }

  // Ajouter un ami
  static Future<void> addFriend(String friendEmail) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('Utilisateur non connecté');
      
      // Vérification 1: Ne pas s'inviter soi-même
      if (currentUser.email == friendEmail) {
        throw Exception('Vous ne pouvez pas vous inviter vous-même');
      }
      
      // Chercher l'ami par email
      final friendSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: friendEmail)
          .get();
      
      if (friendSnapshot.docs.isEmpty) {
        throw Exception('Utilisateur non trouvé');
      }
      
      final friendDoc = friendSnapshot.docs.first;
      final friendUid = friendDoc.id;
      final friendData = friendDoc.data();
      final friendName = friendData['name'] ?? 'Ami';
      
      // Vérification 2: Vérifier si déjà ami
      final existingFriendDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('friends')
          .doc(friendUid)
          .get();
      
      if (existingFriendDoc.exists) {
        throw Exception('Cet utilisateur est déjà dans votre liste d\'amis');
      }
      
      // Vérification 3: Vérifier si invitation déjà envoyée
      final existingInvitationDoc = await _firestore
          .collection('users')
          .doc(friendUid)
          .collection('notifications')
          .where('type', isEqualTo: 'friend_invitation')
          .where('fromUserId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending')
          .get();
      
      if (existingInvitationDoc.docs.isNotEmpty) {
        throw Exception('Vous avez déjà envoyé une invitation à cet utilisateur');
      }
      
      // Récupérer le nom de l'utilisateur actuel
      final currentUserDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final currentUserData = currentUserDoc.data()!;
      final currentUserName = currentUserData['name'] ?? 'Utilisateur';
      
      // Envoyer une notification d'invitation à l'ami
      await NotificationService.sendFriendInvitation(
        currentUser.uid,
        friendUid,
        currentUserName,
      );
      
      // Ajouter l'ami dans la liste de l'utilisateur actuel (en attente)
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('friends')
          .doc(friendUid)
          .set({
        'uid': friendUid,
        'email': friendEmail,
        'addedAt': DateTime.now().toIso8601String(),
        'status': 'pending',
      });
      
      print('Invitation d\'ami envoyée à $friendEmail');
    } catch (e) {
      print('Erreur lors de l\'ajout d\'ami: $e');
      throw e;
    }
  }

  // Mettre à jour les statistiques de l'utilisateur après un jeu
  static Future<void> updateUserGameStats(int score, String gameType) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      final userRef = _firestore.collection('users').doc(currentUser.uid);
      
      // Mettre à jour les statistiques
      await userRef.update({
        'last_game_score': score,
        'last_game_type': gameType,
        'last_active': DateTime.now().toIso8601String(),
        'total_games': FieldValue.increment(1),
      });
      
      // Calculer et mettre à jour le score moyen
      final userDoc = await userRef.get();
      final userData = userDoc.data()!;
      final totalGames = userData['total_games'] ?? 1;
      final currentAvgScore = userData['avg_score'] ?? 0.0;
      
      final newAvgScore = ((currentAvgScore * (totalGames - 1)) + score) / totalGames;
      
      await userRef.update({
        'avg_score': newAvgScore,
      });
      
    } catch (e) {
      print('Erreur lors de la mise à jour des statistiques: $e');
    }
  }

  // Obtenir les statistiques de l'utilisateur actuel
  static Future<Map<String, dynamic>> getCurrentUserStats() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('Utilisateur non connecté');
      
      final prefs = await SharedPreferences.getInstance();
      final userXP = prefs.getInt('user_total_xp') ?? 0;
      final userName = prefs.getString('user_name') ?? currentUser.email?.split('@')[0] ?? 'Utilisateur';
      
      return {
        'uid': currentUser.uid,
        'name': userName,
        'email': currentUser.email ?? '',
        'xp': userXP,
        'level': _getLevelFromXP(userXP),
        'league': _getLeagueFromXP(userXP),
        'avatar': userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
        'country': 'Tunisie',
        'totalGames': prefs.getInt('total_games') ?? 0,
        'avgScore': prefs.getDouble('avg_score') ?? 0.0,
        'lastGameScore': prefs.getInt('last_game_score') ?? 0,
        'winRate': (prefs.getDouble('avg_score') ?? 0.0),
        'streak': prefs.getInt('current_streak') ?? 1,
        'weeklyProgress': 3,
        'isOnline': true,
        'status': 'Joueur actif',
        'badges': ['Active Player'],
        'lastActive': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Erreur lors de la récupération des statistiques: $e');
      throw e;
    }
  }

  // Méthodes utilitaires
  static String _getLevelFromXP(int xp) {
    if (xp < 500) return 'Débutant';
    if (xp < 1500) return 'Intermédiaire';
    if (xp < 5000) return 'Avancé';
    return 'Expert';
  }

  static String _calculateLevel(int xp) {
    if (xp < 100) return 'Débutant';
    if (xp < 300) return 'Intermédiaire';
    if (xp < 600) return 'Avancé';
    if (xp < 1000) return 'Expert';
    return 'Maître';
  }

  static String _getLeagueFromXP(int xp) {
    if (xp < 500) return 'Bronze';
    if (xp < 1500) return 'Argent';
    if (xp < 5000) return 'Or';
    return 'Diamant';
  }

  static bool _isUserOnline(String userId) {
    // Pour la démo, on simule aléatoirement le statut en ligne
    return DateTime.now().millisecondsSinceEpoch % 3 == 0;
  }

  static String _getRankBadge(int rank) {
    switch (rank) {
      case 1: return '1st';
      case 2: return '2nd';
      case 3: return '3rd';
      default: return '${rank}th';
    }
  }

  static String _getWeeklyChange(int rank) {
    final random = Random();
    final change = random.nextInt(7) - 3; // -3 à +3
    
    if (change > 0) return '+$change';
    if (change < 0) return '$change';
    return '0';
  }

  static String _getUserStatus(String level, int totalGames, double avgScore) {
    if (level == 'Expert') return 'Maître des signes';
    if (level == 'Avancé') return 'Apprentissage avancé';
    if (totalGames > 50) return 'Joueur expérimenté';
    if (avgScore > 70) return 'Excellent performer';
    return 'Apprenti passionné';
  }

  // Synchroniser les données locales avec Firebase
  static Future<void> syncUserData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      final userRef = _firestore.collection('users').doc(currentUser.uid);
      
      // Mettre à jour les données dans Firebase
      await userRef.set({
        'name': prefs.getString('user_name'),
        'email': currentUser.email,
        'total_xp': prefs.getInt('user_total_xp') ?? 0,
        'total_games': prefs.getInt('total_games') ?? 0,
        'avg_score': prefs.getDouble('avg_score') ?? 0.0,
        'last_game_score': prefs.getInt('last_game_score') ?? 0,
        'current_streak': prefs.getInt('current_streak') ?? 1,
        'last_active': DateTime.now().toIso8601String(),
        'created_at': FieldValue.serverTimestamp(),
        'country': 'Tunisie',
      }, SetOptions(merge: true));
      
    } catch (e) {
      print('Erreur lors de la synchronisation: $e');
    }
  }
}
