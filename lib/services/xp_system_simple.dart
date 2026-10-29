import 'package:shared_preferences/shared_preferences.dart';

class XPSimple {
  static const String _xpKey = 'user_total_xp';
  static const String _levelKey = 'user_level';
  static const String _streakKey = 'current_streak';
  static const String _lastActiveDateKey = 'last_active_date';
  static const String _leagueKey = 'user_league';
  static const String _badgesKey = 'user_badges';

  // Configuration des XP par jeu
  static const Map<String, int> _xpParJeu = {
    'trouve_image': 10,      // 10 XP par série de 5 mots
    'ecris_mot': 15,         // 15 XP par série de 5 mots
    'reconnaissance_camera': 25, // 25 XP par signe
  };

  // Configuration des bonus
  static const int _bonusPerfect = 2;       // +2 XP si aucun échec
  static const int _bonusRapidite = 3;      // +3 XP si fini en moins de 30 secondes
  static const int _bonusComplexe = 10;     // +10 XP si signe complexe
  static const int _streakQuotidien = 30;    // 30 XP par jour pour valider la série
  static const int _streakHebdomadaire = 50;    // 50 XP pour série de 7 jours
  static const int _shieldCost = 200;        // 200 XP pour un protège-série

  // Configuration des ligues
  static const Map<String, Map<String, dynamic>> _ligues = {
    'Bronze': {
      'nom': 'Ligue de Bronze',
      'description': 'Pour les débutants qui apprennent leurs 10 premiers signes',
      'couleur': 0xFFCD7F32, // Orange bronze
      'xp_requis': 0,
      'icone': '🥉',
    },
    'Argent': {
      'nom': 'Ligue d\'Argent',
      'description': 'Pour ceux qui commencent à utiliser la caméra',
      'couleur': 0xFFC0C0C0, // Gris argent
      'xp_requis': 500,
      'icone': '🥈',
    },
    'Or': {
      'nom': 'Ligue d\'Or',
      'description': 'Pour ceux qui maîtrisent l\'écriture et les signes complexes',
      'couleur': 0xFFFFD700, // Or
      'xp_requis': 1500,
      'icone': '🥇',
    },
    'Diamant': {
      'nom': 'Ligue de Diamant',
      'description': 'Le top 5% des utilisateurs',
      'couleur': 0xFFB9F2FF, // Bleu diamant
      'xp_requis': 5000,
      'icone': '💎',
    },
  };

  static Future<int> getTotalXP() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_xpKey) ?? 0;
  }

  static Future<void> setTotalXP(int xp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_xpKey, xp);
    await _updateLevel();
    await _updateLeague();
  }

  static Future<String> getLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_levelKey) ?? 'Débutant';
  }

  static Future<void> _updateLevel() async {
    final totalXP = await getTotalXP();
    String level;
    
    if (totalXP < 500) {
      level = 'Débutant';
    } else if (totalXP < 1500) {
      level = 'Intermédiaire';
    } else {
      level = 'Expert';
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_levelKey, level);
  }

  static Future<String> getLeague() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_leagueKey) ?? 'Bronze';
  }

  static Future<void> _updateLeague() async {
    final totalXP = await getTotalXP();
    String league = 'Bronze';
    
    for (String nomLigue in _ligues.keys) {
      if (totalXP >= _ligues[nomLigue]!['xp_requis']) {
        league = nomLigue;
      }
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_leagueKey, league);
  }

  static Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_streakKey) ?? 0;
  }

  static Future<void> setStreak(int streak) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_streakKey, streak);
  }

  static Future<void> incrementStreak() async {
    final currentStreak = await getStreak();
    await setStreak(currentStreak + 1);
    
    // Bonus de série quotidienne
    await addXP(_streakQuotidien, "Série quotidienne");
  }

  static Future<void> resetStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_streakKey, 0);
  }

  static Future<bool> canUseShield() async {
    final totalXP = await getTotalXP();
    return totalXP >= _shieldCost;
  }

  static Future<void> useShield() async {
    if (!(await canUseShield())) return;
    
    final totalXP = await getTotalXP();
    await setTotalXP(totalXP - _shieldCost);
  }

  static Future<void> addXP(int xp, String source) async {
    final currentXP = await getTotalXP();
    final newXP = currentXP + xp;
    await setTotalXP(newXP);
  }

  static Future<void> addXPWithBonus(String jeu, bool success, {bool? rapidite, bool? complexe}) async {
    if (!success) return;
    
    int baseXP = _xpParJeu[jeu] ?? 0;
    int totalBonus = 0;
    
    // Bonus Perfect (aucun échec)
    if (success) {
      totalBonus += _bonusPerfect;
    }
    
    // Bonus Rapidité (moins de 30 secondes)
    if (rapidite == true) {
      totalBonus += _bonusRapidite;
    }
    
    // Bonus Complexité (signes difficiles)
    if (complexe == true) {
      totalBonus += _bonusComplexe;
    }
    
    final totalXP = baseXP + totalBonus;
    await addXP(totalXP, "$jeu avec bonus");
  }

  static Future<void> checkAndAwardBadges() async {
    // TODO: Implémenter les médailles plus tard si nécessaire
  }

  static Future<void> recordGameResult(String jeu, bool success, {String? signe, bool? complexe}) async {
    // Ajouter les XP avec bonus
    await addXPWithBonus(jeu, success, rapidite: false, complexe: complexe);
    
    // Gérer la série quotidienne
    await _handleDailyStreak();
  }

  static Future<void> _handleDailyStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActiveDate = prefs.getString(_lastActiveDateKey);
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    
    if (lastActiveDate != todayString) {
      // Nouveau jour, bonus de série
      await incrementStreak();
      await prefs.setString(_lastActiveDateKey, todayString);
      
      // Bonus série hebdomadaire
      final streak = await getStreak();
      if (streak % 7 == 0) {
        await addXP(_streakHebdomadaire, "Série hebdomadaire");
      }
    }
  }

  static Future<Map<String, dynamic>> getUserStats() async {
    return {
      'total_xp': await getTotalXP(),
      'level': await getLevel(),
      'league': await getLeague(),
      'league_info': await _getLeagueInfo(),
      'streak': await getStreak(),
      'can_use_shield': await canUseShield(),
    };
  }

  static Future<Map<String, dynamic>> _getLeagueInfo() async {
    final leagueName = await getLeague();
    return _ligues[leagueName] ?? _ligues['Bronze']!;
  }
}
