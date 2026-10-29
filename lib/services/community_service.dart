import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class CommunityService {
  static const String _friendsKey = 'friends_list';
  static const String _leaderboardKey = 'leaderboard_data';
  static const String _userStatsKey = 'user_community_stats';

  // Base de données des joueurs existants
  static const List<Map<String, dynamic>> _basePlayers = [
    {
      'name': 'Leila Ben Ali',
      'level': 'Expert',
      'xp': 5500,
      'league': 'Diamant',
      'avatar': 'L',
      'country': 'Tunisie',
      'joinDate': '2024-01-15',
      'totalGames': 342,
      'winRate': 87.5,
      'streak': 15,
      'weeklyProgress': 12,
      'isOnline': true,
      'status': 'Maîtrise des signes complexes',
      'badges': ['Pionnier', 'Mentor', 'Champion'],
    },
    {
      'name': 'Sarah Trabelsi',
      'level': 'Avancé',
      'xp': 2100,
      'league': 'Or',
      'avatar': 'S',
      'country': 'Tunisie',
      'joinDate': '2024-02-20',
      'totalGames': 189,
      'winRate': 78.2,
      'streak': 8,
      'weeklyProgress': 6,
      'isOnline': true,
      'status': 'Apprentissage avancé',
      'badges': ['Dedicated', 'Fast Learner'],
    },
    {
      'name': 'Karim Mejri',
      'level': 'Intermédiaire',
      'xp': 1800,
      'league': 'Argent',
      'avatar': 'K',
      'country': 'Algérie',
      'joinDate': '2024-03-10',
      'totalGames': 156,
      'winRate': 72.1,
      'streak': 5,
      'weeklyProgress': -1,
      'isOnline': false,
      'status': 'Progression constante',
      'badges': ['Consistent'],
    },
    {
      'name': 'Ahmed Sassi',
      'level': 'Intermédiaire',
      'xp': 850,
      'league': 'Argent',
      'avatar': 'A',
      'country': 'Maroc',
      'joinDate': '2024-04-05',
      'totalGames': 98,
      'winRate': 68.5,
      'streak': 4,
      'weeklyProgress': 4,
      'isOnline': true,
      'status': 'Apprentissage en cours',
      'badges': ['Rising Star'],
    },
    {
      'name': 'Nadia Khaled',
      'level': 'Débutant',
      'xp': 650,
      'league': 'Bronze',
      'avatar': 'N',
      'country': 'Libye',
      'joinDate': '2024-04-20',
      'totalGames': 67,
      'winRate': 61.3,
      'streak': 2,
      'weeklyProgress': 3,
      'isOnline': false,
      'status': 'Découverte des bases',
      'badges': ['Newcomer'],
    },
    {
      'name': 'Mohamed Gharbi',
      'level': 'Débutant',
      'xp': 320,
      'league': 'Bronze',
      'avatar': 'M',
      'country': 'Tunisie',
      'joinDate': '2024-05-01',
      'totalGames': 45,
      'winRate': 55.8,
      'streak': 1,
      'weeklyProgress': 2,
      'isOnline': false,
      'status': 'Premiers pas',
      'badges': ['Beginner'],
    },
    {
      'name': 'Fatma Zohra',
      'level': 'Expert',
      'xp': 4800,
      'league': 'Diamant',
      'avatar': 'F',
      'country': 'Tunisie',
      'joinDate': '2023-12-10',
      'totalGames': 412,
      'winRate': 91.2,
      'streak': 22,
      'weeklyProgress': 8,
      'isOnline': true,
      'status': 'Expert en signes quotidiens',
      'badges': ['Legend', 'Perfect', 'Master'],
    },
    {
      'name': 'Youssef Brahmi',
      'level': 'Avancé',
      'xp': 3200,
      'league': 'Or',
      'avatar': 'Y',
      'country': 'France',
      'joinDate': '2024-01-28',
      'totalGames': 267,
      'winRate': 82.4,
      'streak': 11,
      'weeklyProgress': 5,
      'isOnline': true,
      'status': 'Spécialiste signes familiaux',
      'badges': ['Specialist', 'Dedicated'],
    },
  ];

  // Noms aléatoires pour les amis invités
  static const List<Map<String, String>> _randomNames = [
    {'name': 'Thomas Dubois', 'country': 'France'},
    {'name': 'Marie Laurent', 'country': 'France'},
    {'name': 'Lucas Martin', 'country': 'France'},
    {'name': 'Emma Bernard', 'country': 'France'},
    {'name': 'Hugo Petit', 'country': 'France'},
    {'name': 'Chloé Robert', 'country': 'France'},
    {'name': 'Louis Girard', 'country': 'France'},
    {'name': 'Camille Durand', 'country': 'France'},
    {'name': 'Arthur Moreau', 'country': 'France'},
    {'name': 'Léa Blanc', 'country': 'France'},
  ];

  static Future<List<Map<String, dynamic>>> getLeaderboard() async {
    final prefs = await SharedPreferences.getInstance();
    final userXP = prefs.getInt('user_total_xp') ?? 0;
    final userName = prefs.getString('user_name') ?? 'Utilisateur';
    final random = Random();

    // Créer une copie des joueurs de base avec variations aléatoires
    List<Map<String, dynamic>> dynamicPlayers = _basePlayers.map((player) {
      final xpVariation = random.nextInt(200) - 100; // -100 à +100
      final progressVariation = random.nextInt(5) - 2; // -2 à +2
      
      return Map<String, dynamic>.from(player)
        ..['xp'] = (player['xp'] as int) + xpVariation
        ..['weeklyProgress'] = (player['weeklyProgress'] as int) + progressVariation
        ..['isOnline'] = random.nextBool(); // Statut en ligne aléatoire
    }).toList();

    // Ajouter l'utilisateur actuel au classement
    dynamicPlayers.add({
      'name': userName,
      'xp': userXP,
      'level': _getLevelFromXP(userXP),
      'league': _getLeagueFromXP(userXP),
      'avatar': userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
      'country': 'Tunisie',
      'joinDate': '2024-05-15',
      'totalGames': random.nextInt(100) + 20,
      'winRate': 60.0 + random.nextDouble() * 30.0,
      'streak': random.nextInt(10) + 1,
      'weeklyProgress': random.nextInt(8) - 2,
      'isOnline': true,
      'status': 'Joueur actif',
      'badges': ['Active Player'],
      'isCurrentUser': true,
    });

    // Trier par XP décroissant
    dynamicPlayers.sort((a, b) => (b['xp'] as int).compareTo(a['xp'] as int));

    // Assigner les rangs et les médailles
    for (int i = 0; i < dynamicPlayers.length; i++) {
      dynamicPlayers[i]['rank'] = i + 1;
      dynamicPlayers[i]['badge'] = _getRankBadge(i + 1);
      dynamicPlayers[i]['weeklyChange'] = _getWeeklyChange(i);
    }

    // Sauvegarder le classement
    await _saveLeaderboard(dynamicPlayers);
    
    return dynamicPlayers;
  }

  static Future<List<Map<String, dynamic>>> getFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final friendsJson = prefs.getString(_friendsKey);
    
    if (friendsJson != null) {
      // Charger les amis existants
      return _parseFriendsList(friendsJson);
    } else {
      // Créer des amis initiaux
      final initialFriends = [
        _basePlayers[1], // Sarah
        _basePlayers[3], // Ahmed
        _basePlayers[5], // Mohamed
      ];
      
      await _saveFriends(initialFriends);
      return initialFriends;
    }
  }

  static Future<void> addFriend(String friendName) async {
    final friends = await getFriends();
    
    // Vérifier si l'ami existe déjà
    if (friends.any((friend) => friend['name'] == friendName)) {
      throw Exception('Cet ami est déjà dans votre liste');
    }

    // Créer un nouvel ami
    final random = Random();
    final newFriend = {
      'name': friendName,
      'level': 'Débutant',
      'xp': random.nextInt(300),
      'league': 'Bronze',
      'avatar': friendName.isNotEmpty ? friendName[0].toUpperCase() : '?',
      'country': 'Tunisie',
      'joinDate': DateTime.now().toString().split(' ')[0],
      'totalGames': random.nextInt(50),
      'winRate': 50.0 + random.nextDouble() * 20.0,
      'streak': random.nextInt(5),
      'weeklyProgress': 0,
      'isOnline': false,
      'status': 'Invitation envoyée',
      'badges': ['Newcomer'],
    };

    friends.add(newFriend);
    await _saveFriends(friends);
  }

  static Future<void> updateFriendProgress(String friendName) async {
    final friends = await getFriends();
    final friendIndex = friends.indexWhere((friend) => friend['name'] == friendName);
    
    if (friendIndex != -1) {
      final random = Random();
      final friend = friends[friendIndex];
      
      // Mettre à jour les progrès
      friend['xp'] = (friend['xp'] as int) + random.nextInt(50);
      friend['weeklyProgress'] = (friend['weeklyProgress'] as int) + random.nextInt(3);
      friend['totalGames'] = (friend['totalGames'] as int) + 1;
      friend['isOnline'] = random.nextBool();
      
      // Mettre à jour le niveau et la ligue
      friend['level'] = _getLevelFromXP(friend['xp'] as int);
      friend['league'] = _getLeagueFromXP(friend['xp'] as int);
      
      // Changer le statut si nécessaire
      if (friend['status'] == 'Invitation envoyée' && random.nextBool()) {
        friend['status'] = 'Apprentissage en cours';
        friend['isOnline'] = true;
      }
      
      await _saveFriends(friends);
    }
  }

  static Future<Map<String, dynamic>> getUserStats() async {
    final prefs = await SharedPreferences.getInstance();
    final userXP = prefs.getInt('user_total_xp') ?? 0;
    final userName = prefs.getString('user_name') ?? 'Utilisateur';
    
    return {
      'name': userName,
      'xp': userXP,
      'level': _getLevelFromXP(userXP),
      'league': _getLeagueFromXP(userXP),
      'avatar': userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
      'country': 'Tunisie',
      'joinDate': '2024-05-15',
      'totalGames': prefs.getInt('total_games') ?? 0,
      'winRate': 65.0,
      'streak': prefs.getInt('current_streak') ?? 1,
      'weeklyProgress': 3,
      'isOnline': true,
      'status': 'Joueur actif',
      'badges': ['Active Player'],
    };
  }

  static String _getLevelFromXP(int xp) {
    if (xp < 500) return 'Débutant';
    if (xp < 1500) return 'Intermédiaire';
    if (xp < 5000) return 'Avancé';
    return 'Expert';
  }

  static String _getLeagueFromXP(int xp) {
    if (xp < 500) return 'Bronze';
    if (xp < 1500) return 'Argent';
    if (xp < 5000) return 'Or';
    return 'Diamant';
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

  static Future<void> _saveFriends(List<Map<String, dynamic>> friends) async {
    final prefs = await SharedPreferences.getInstance();
    final friendsJson = _encodeFriendsList(friends);
    await prefs.setString(_friendsKey, friendsJson);
  }

  static Future<void> _saveLeaderboard(List<Map<String, dynamic>> leaderboard) async {
    final prefs = await SharedPreferences.getInstance();
    final leaderboardJson = _encodeLeaderboard(leaderboard);
    await prefs.setString(_leaderboardKey, leaderboardJson);
  }

  static String _encodeFriendsList(List<Map<String, dynamic>> friends) {
    // Simplification - en réalité, utiliserait jsonEncode
    return friends.map((friend) => '${friend['name']}|${friend['xp']}|${friend['level']}').join(';');
  }

  static List<Map<String, dynamic>> _parseFriendsList(String friendsJson) {
    // Simplification - en réalité, utiliserait jsonDecode
    final friendsData = friendsJson.split(';');
    return friendsData.map((data) {
      final parts = data.split('|');
      return {
        'name': parts[0],
        'xp': int.tryParse(parts[1]) ?? 0,
        'level': parts.length > 2 ? parts[2] : 'Débutant',
        'league': _getLeagueFromXP(int.tryParse(parts[1]) ?? 0),
        'avatar': parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?',
        'weeklyProgress': Random().nextInt(5),
        'isOnline': Random().nextBool(),
        'status': 'Apprentissage en cours',
      };
    }).toList();
  }

  static String _encodeLeaderboard(List<Map<String, dynamic>> leaderboard) {
    // Simplification pour la sauvegarde
    return 'leaderboard_saved';
  }

  static String getRandomFriendName() {
    final random = Random();
    final nameData = _randomNames[random.nextInt(_randomNames.length)];
    return nameData['name']!;
  }

  static Future<void> simulateDailyActivity() async {
    final friends = await getFriends();
    
    // Mettre à jour aléatoirement quelques amis
    for (int i = 0; i < min(3, friends.length); i++) {
      final random = Random();
      final friendIndex = random.nextInt(friends.length);
      await updateFriendProgress(friends[friendIndex]['name']);
    }
  }

  static Future<List<Map<String, dynamic>>> getTopPlayers(int limit) async {
    final leaderboard = await getLeaderboard();
    return leaderboard.take(limit).toList();
  }

  static Future<Map<String, dynamic>> getPlayerStats(String playerName) async {
    final leaderboard = await getLeaderboard();
    final player = leaderboard.firstWhere(
      (player) => player['name'] == playerName,
      orElse: () => throw Exception('Joueur non trouvé'),
    );
    return player;
  }
}
