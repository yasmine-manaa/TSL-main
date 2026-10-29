import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../services/user_service.dart';
import '../services/profile_image_service.dart';
import 'edit_profile_page.dart';
import 'login_page.dart';

const Color primaryRed = Color(0xFFE60012);
const Color bgGrey = Color(0xFFF5F5F5);
const Color lightRed = Color(0xFFFFE5E5);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _userName = 'Chargement...';
  String _userEmail = 'Chargement...';
  int _userXP = 0;
  String _userLevel = 'Débutant';
  int _gamesPlayed = 0;
  int _lastGameScore = 0;
  double _avgScore = 0.0;
  bool _isLoading = true;
  String? _profileImagePath;
  bool _hasProfileImage = false;
  String _birthDate = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    // Charger l'image de profil indépendamment
    _loadProfileImage();
  }

  Future<void> _loadUserInfo() async {
    setState(() => _isLoading = true);
    
    try {
      final userInfo = await UserService.getUserInfo();
      final gameStats = await UserService.getGameStats();
      
      // Charger la date de naissance depuis SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final birthDate = prefs.getString('birth_date') ?? '';
      
      if (gameStats['success'] == true) {
        final stats = gameStats['stats'];
        setState(() {
          _userName = userInfo['name'] ?? 'Utilisateur';
          _userEmail = userInfo['email'] ?? 'email@example.com';
          _userXP = stats['total_xp'] ?? 0;
          _userLevel = stats['level'] ?? 'Débutant';
          _gamesPlayed = stats['games_played'] ?? 0;
          _lastGameScore = stats['last_game_score'] ?? 0;
          _avgScore = (stats['avg_score'] ?? 0.0).toDouble();
          _birthDate = birthDate;
          _isLoading = false;
        });
      } else {
        // Fallback si les stats ne sont pas disponibles
        final userInfo = await UserService.getUserInfo();
        setState(() {
          _userName = userInfo['name'] ?? 'Utilisateur';
          _userEmail = userInfo['email'] ?? 'email@example.com';
          _userXP = 0; // Valeur par défaut
          _userLevel = 'Débutant';
          _birthDate = birthDate;
          _isLoading = false;
        });
      }
      
      // Charger l'image de profil
      await _loadProfileImage();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProfileImage() async {
    try {
      // Utiliser le nouveau service Firebase
      final imageData = await ProfileImageService.getProfileImage();
      final hasImage = await ProfileImageService.hasProfileImage();
      
      setState(() {
        _profileImagePath = imageData;
        _hasProfileImage = hasImage;
      });
    } catch (e) {
      print('Erreur lors du chargement de l\'image de profil: $e');
      if (mounted) {
        setState(() {
          _profileImagePath = null;
          _hasProfileImage = false;
        });
      }
    }
  }

  // Méthode de déconnexion
  Future<void> _logout() async {
    try {
      // Afficher un dialogue de confirmation
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Déconnexion',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await UserService.logout();
        
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => LoginPage(),
            ),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Widget pour construire l'image de profil avec gestion d'erreur
  Widget _buildProfileImage() {
    try {
      print('🖼️ Tentative d\'affichage de l\'image de profil');
      print('📏 Taille de l\'image: ${_profileImagePath?.length ?? 0} caractères');
      
      if (_profileImagePath == null || _profileImagePath!.isEmpty) {
        print('❌ Image vide ou nulle');
        return _buildDefaultAvatar();
      }
      
      // Vérifier si c'est du base64
      if (_profileImagePath!.startsWith('data:image')) {
        final base64String = _profileImagePath!.split(',')[1];
        print('✅ Image Base64 détectée, décodage...');
        
        final imageBytes = base64Decode(base64String);
        print('✅ Décodage réussi, ${imageBytes.length} bytes');
        
        return Image.memory(
          imageBytes,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('❌ Erreur d\'affichage: $error');
            return _buildDefaultAvatar();
          },
        );
      } else {
        print('⚠️ Format d\'image non reconnu: ${_profileImagePath!.substring(0, 50)}...');
        return _buildDefaultAvatar();
      }
    } catch (e) {
      print('❌ Erreur lors de la construction de l\'image: $e');
      return _buildDefaultAvatar();
    }
  }

  // Widget pour l'avatar par défaut
  Widget _buildDefaultAvatar() {
    print('🔤 Affichage de l\'avatar par défaut avec lettre: ${_userName.isNotEmpty ? _userName[0].toUpperCase() : 'U'}');
    return Center(
      child: Text(
        _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: primaryRed,
        ),
      ),
    );
  }

  String _calculateLevel(int xp) {
    if (xp < 100) return 'Débutant';
    if (xp < 300) return 'Intermédiaire';
    if (xp < 600) return 'Avancé';
    if (xp < 1000) return 'Expert';
    return 'Maître';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Profil",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Information Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryRed,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: _hasProfileImage && _profileImagePath != null
                              ? _buildProfileImage()
                              : _buildDefaultAvatar(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // User Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _userEmail,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            if (_birthDate.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                _birthDate,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            // Edit Button
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProfilePage(),
                                  ),
                                ).then((_) {
                                  // Recharger les infos quand on revient
                                  _loadUserInfo();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: primaryRed,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                "Modifier",
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Moon and Star Icon
                  const Positioned(
                    top: 10,
                    right: 10,
                    child: Icon(
                      Icons.nightlight_round,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Statistics Section
            const Text(
              "Statistiques",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                // XP Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "$_userXP",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Points XP",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Level Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: primaryRed,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _userLevel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Niveau",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Games Played Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.sports_esports,
                          color: Colors.blue,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "$_gamesPlayed",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Jeux joués",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Logout Button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  "Déconnexion",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Learning Progress Section
            const Text(
              "Progrès d'apprentissage",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Niveau actuel",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: 0.32,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: const AlwaysStoppedAnimation<Color>(primaryRed),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Débutant",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "32% vers le niveau Intermédiaire",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Recently Learned Words Section
            const Text(
              "Mots récemment appris",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildRecentlyLearnedWord("Bonjour", "Hello"),
                  const Divider(),
                  _buildRecentlyLearnedWord("Merci", "Thank you"),
                  const Divider(),
                  _buildRecentlyLearnedWord("Au revoir", "Goodbye"),
                  const Divider(),
                  _buildRecentlyLearnedWord("S'il vous plaît", "Please"),
                  const Divider(),
                  _buildRecentlyLearnedWord("Excusez-moi", "Excuse me"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentlyLearnedWord(String frenchWord, String englishWord) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: lightRed,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.sign_language,
              color: primaryRed,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  frenchWord,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  englishWord,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.play_circle_outline,
            color: primaryRed,
            size: 24,
          ),
        ],
      ),
    );
  }
}
