import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/xp_system_simple.dart';

const Color primaryRed = Color(0xFFE60012);
const Color bgGrey = Color(0xFFF5F5F5);
const Color lightRed = Color(0xFFFFE5E5);
const Color goldColor = Color(0xFFFFD700);
const Color silverColor = Color(0xFFC0C0C0);
const Color bronzeColor = Color(0xFFCD7F32);

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  String? _userParrainCode;
  String? _userLevel;
  String? _userLeague;
  int _userXP = 0;
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadFriends();
    _loadLeaderboard();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userParrainCode = prefs.getString('parrain_code');
      _userLevel = prefs.getString('user_level') ?? 'Débutant';
      _userLeague = prefs.getString('user_league') ?? 'Bronze';
      _userXP = prefs.getInt('user_total_xp') ?? 0;
      _isLoading = false;
    });
  }

  Future<void> _loadFriends() async {
    // Simuler des amis (à remplacer par votre backend)
    setState(() {
      _friends = [
        {
          'name': 'Ahmed',
          'level': 'Intermédiaire',
          'xp': 850,
          'league': 'Argent',
          'avatar': 'A',
          'weeklyProgress': 4,
          'isOnline': true,
        },
        {
          'name': 'Sarah',
          'level': 'Avancé',
          'xp': 2100,
          'league': 'Or',
          'avatar': 'S',
          'weeklyProgress': 6,
          'isOnline': true,
        },
        {
          'name': 'Mohamed',
          'level': 'Débutant',
          'xp': 320,
          'league': 'Bronze',
          'avatar': 'M',
          'weeklyProgress': 2,
          'isOnline': false,
        },
        {
          'name': 'Leila',
          'level': 'Expert',
          'xp': 5500,
          'league': 'Diamant',
          'avatar': 'L',
          'weeklyProgress': 7,
          'isOnline': true,
        },
      ];
    });
  }

  Future<void> _loadLeaderboard() async {
    // Simuler le classement (à remplacer par votre backend)
    setState(() {
      _leaderboard = [
        {
          'rank': 1,
          'name': 'Leila',
          'xp': 5500,
          'level': 'Expert',
          'league': 'Diamant',
          'avatar': 'L',
          'badge': '🏆',
        },
        {
          'rank': 2,
          'name': 'Sarah',
          'xp': 2100,
          'level': 'Avancé',
          'league': 'Or',
          'avatar': 'S',
          'badge': '🥇',
        },
        {
          'rank': 3,
          'name': 'Karim',
          'xp': 1800,
          'level': 'Intermédiaire',
          'league': 'Argent',
          'avatar': 'K',
          'badge': '🥈',
        },
        {
          'rank': 4,
          'name': 'Ahmed',
          'xp': 850,
          'level': 'Intermédiaire',
          'league': 'Argent',
          'avatar': 'A',
          'badge': '🥈',
        },
        {
          'rank': 5,
          'name': 'Nadia',
          'xp': 650,
          'level': 'Débutant',
          'league': 'Bronze',
          'avatar': 'N',
          'badge': '🥉',
        },
      ];
    });
  }

  String _generateParrainCode() {
    final random = Random();
    final code = 'SIGN-${random.nextInt(900) + 100}';
    return code;
  }

  Future<void> _saveParrainCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('parrain_code', code);
    setState(() {
      _userParrainCode = code;
    });
  }

  Future<void> _shareParrainCode() async {
    // Simuler le partage (à remplacer par votre système de partage)
    print('🔗 Partage du code parrain: $_userParrainCode');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.share, color: Colors.white),
            SizedBox(width: 8),
            Text("Code parrain copié dans le presse-papiers"),
          ],
        ),
        backgroundColor: primaryRed,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _inviteFriend() async {
    // Simuler l'invitation (à remplacer par votre backend)
    print('📧 Invitation d\'ami envoyée');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.person_add, color: Colors.white),
            SizedBox(width: 8),
            Text("Invitation envoyée avec succès!"),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _claimParrainBonus() async {
    if (_userParrainCode == null || _userParrainCode!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text("Veuillez d'abord générer un code parrain"),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Simuler la réclamation du bonus (à remplacer par votre backend)
    await XPSimple.addXP(100, "Bonus parrainage");
    await _loadUserData(); // Recharger les données
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.card_giftcard, color: Colors.white),
            SizedBox(width: 8),
            Text("+100 XP bonus parrainage!"),
          ],
        ),
        backgroundColor: goldColor,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Color _getLeagueColor(String league) {
    switch (league) {
      case 'Bronze':
        return bronzeColor;
      case 'Argent':
        return silverColor;
      case 'Or':
        return goldColor;
      case 'Diamant':
        return Colors.blue.shade300;
      default:
        return bronzeColor;
    }
  }

  Widget _buildUserCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: _getLeagueColor(_userLeague!),
                child: Text(
                  _userLevel![0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Niveau $_userLevel",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryRed,
                      ),
                    ),
                    Text(
                      "Ligue ${_userLeague!}",
                      style: TextStyle(
                        fontSize: 14,
                        color: _getLeagueColor(_userLeague!),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "$_userXP XP",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryRed,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_userXP % 5000) / 5000,
            backgroundColor: Colors.grey.shade300,
            valueColor: primaryRed,
          ),
          const SizedBox(height: 8),
          Text(
            "${((_userXP % 5000) / 5000 * 100).toStringAsFixed(1)}% vers le niveau suivant",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildParrainSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "🎁 Code Parrainage",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryRed,
            ),
          ),
          const SizedBox(height: 12),
          if (_userParrainCode == null || _userParrainCode!.isEmpty)
            Column(
              children: [
                const Text(
                  "Générez votre code unique pour inviter vos amis",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final newCode = _generateParrainCode();
                      _saveParrainCode(newCode);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text("Générer un code"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRed,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryRed.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Votre code: $_userParrainCode",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryRed,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _shareParrainCode,
                        icon: const Icon(Icons.share, color: primaryRed),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _claimParrainBonus,
                        icon: const Icon(Icons.card_giftcard),
                        label: const Text("Réclamer bonus (+100 XP)"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: goldColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        final newCode = _generateParrainCode();
                        _saveParrainCode(newCode);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text("Nouveau code"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFriendsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "👥 Mes Amis",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryRed,
                ),
              ),
              IconButton(
                onPressed: _inviteFriend,
                icon: const Icon(Icons.person_add, color: primaryRed),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_friends.isEmpty)
            const Center(
              child: Text(
                "Aucun ami pour le moment. Invitez vos amis!",
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ..._friends.map((friend) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _getLeagueColor(friend['league']),
                      child: Text(
                        friend['avatar'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friend['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                friend['level'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getLeagueColor(friend['league']),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "${friend['xp']} XP",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.trending_up,
                                size: 16,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "+${friend['weeklyProgress']} cette semaine",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (friend['isOnline'])
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    "En ligne",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )).toList(),
        ],
      ),
    );
  }

  Widget _buildLeaderboardSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "🏆 Classement",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryRed,
            ),
          ),
          const SizedBox(height: 16),
          ..._leaderboard.asMap().entries.map((entry) {
            final index = entry.key;
            final player = entry.value;
            final isCurrentUser = player['name'] == 'Moi'; // À remplacer par le nom de l'utilisateur
            
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrentUser ? primaryRed.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isCurrentUser 
                  ? Border.all(color: primaryRed.withOpacity(0.3))
                  : null,
              ),
              child: Row(
                children: [
                  Text(
                    "#${index + 1}",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isCurrentUser ? primaryRed : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (player['badge'] != null)
                    Text(
                      player['badge'],
                      style: const TextStyle(fontSize: 20),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player['name'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isCurrentUser ? primaryRed : Colors.black87,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              player['level'],
                              style: TextStyle(
                                fontSize: 12,
                                color: _getLeagueColor(player['league']),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${player['xp']} XP",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgGrey,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Communauté",
          style: TextStyle(
            color: primaryRed,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryRed),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildUserCard(),
            const SizedBox(height: 16),
            _buildParrainSection(),
            const SizedBox(height: 16),
            _buildFriendsSection(),
            const SizedBox(height: 16),
            _buildLeaderboardSection(),
          ],
        ),
      ),
    );
  }
}
