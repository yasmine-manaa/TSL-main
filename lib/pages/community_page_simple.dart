import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
import '../services/firebase_community_service.dart';
import '../widgets/navigation_wrapper.dart';

const Color primaryRed = Color(0xFFE60012);
const Color bgGrey = Color(0xFFF5F5F5);

class CommunityPageSimple extends StatefulWidget {
  const CommunityPageSimple({super.key});

  @override
  State<CommunityPageSimple> createState() => _CommunityPageSimpleState();
}

class _CommunityPageSimpleState extends State<CommunityPageSimple> {
  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      await Future.wait([
        _loadPendingRequests(),
        _loadFriends(),
        _loadLeaderboard(),
      ]);
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
    }
  }

  Future<void> _loadPendingRequests() async {
    try {
      print('PAGE COMMUNAUTE - Chargement des invitations en attente...');
      final requests = await NotificationService.getPendingFriendRequests();
      print('PAGE COMMUNAUTE - Invitations trouvées: ${requests.length}');
      for (var request in requests) {
        print('PAGE COMMUNAUTE - Invitation: ${request['fromUserName']} - NotifID: ${request['notificationId']} - UserID: ${request['fromUserId']}');
      }
      setState(() {
        _pendingRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      print('PAGE COMMUNAUTE - Erreur lors du chargement des invitations: $e');
      setState(() {
        _pendingRequests = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFriends() async {
    try {
      final friends = await FirebaseCommunityService.getUserFriends();
      setState(() {
        _friends = friends;
      });
    } catch (e) {
      print('Erreur lors du chargement des amis: $e');
      setState(() {
        _friends = [];
      });
    }
  }

  Future<void> _loadLeaderboard() async {
    try {
      final leaderboard = await FirebaseCommunityService.getRealLeaderboard();
      setState(() {
        _leaderboard = leaderboard;
      });
    } catch (e) {
      print('Erreur lors du chargement du classement: $e');
      setState(() {
        _leaderboard = [];
      });
    }
  }

  Future<void> _acceptInvitation(String notificationId, String fromUserId) async {
    try {
      print('PAGE COMMUNAUTE - Acceptation: notificationId=$notificationId, fromUserId=$fromUserId');
      await NotificationService.acceptFriendInvitation(notificationId, fromUserId);
      
      // Recharger uniquement les données nécessaires sans reconstruire toute la page
      await _loadPendingRequests();
      await _loadFriends();
      
      _showSuccessMessage('Invitation acceptée !');
    } catch (e) {
      print('PAGE COMMUNAUTE - Erreur acceptation: $e');
      _showErrorMessage('Erreur: ${e.toString()}');
    }
  }

  Future<void> _rejectInvitation(String notificationId, String fromUserId) async {
    try {
      print('PAGE COMMUNAUTE - Refus: notificationId=$notificationId, fromUserId=$fromUserId');
      await NotificationService.rejectFriendInvitation(notificationId, fromUserId);
      
      // Recharger uniquement les invitations en attente
      await _loadPendingRequests();
      
      _showSuccessMessage('Invitation refusée');
    } catch (e) {
      print('PAGE COMMUNAUTE - Erreur refus: $e');
      _showErrorMessage('Erreur: ${e.toString()}');
    }
  }

  Future<void> _searchFriends(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _searchResults = [];
        });
        return;
      }

      // Récupérer tous les utilisateurs
      final allUsers = await FirebaseCommunityService.getRealUsers();
      
      // Récupérer la liste des amis existants
      final existingFriends = await FirebaseCommunityService.getUserFriends();
      final friendIds = existingFriends.map((friend) => friend['uid'] as String).toSet();
      
      // Filtrer les utilisateurs
      final filteredUsers = allUsers.where((user) {
        // Exclure l'utilisateur actuel
        if (user['uid'] == currentUser.uid) return false;
        
        // Exclure les amis existants
        if (friendIds.contains(user['uid'])) return false;
        
        // Filtrer par nom ou email
        final name = user['name'].toString().toLowerCase();
        final email = user['email'].toString().toLowerCase();
        final searchQuery = query.toLowerCase();
        
        return name.contains(searchQuery) || email.contains(searchQuery);
      }).toList();

      setState(() {
        _searchResults = filteredUsers;
      });
    } catch (e) {
      print('Erreur lors de la recherche: $e');
      setState(() {
        _searchResults = [];
      });
    }
  }

  Future<void> _sendFriendRequest(Map<String, dynamic> user) async {
    try {
      await FirebaseCommunityService.addFriend(user['email']);
      
      // Recharger uniquement les données nécessaires
      await _loadPendingRequests();
      await _loadFriends();
      
      _searchController.clear();
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      _showSuccessMessage('Invitation envoyée à ${user['name']}!');
    } catch (e) {
      _showErrorMessage('Erreur: ${e.toString()}');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Color _getLeagueColor(String league) {
    switch (league) {
      case 'Bronze':
        return const Color(0xFFCD7F32);
      case 'Argent':
        return const Color(0xFFC0C0C0);
      case 'Or':
        return const Color(0xFFFFD700);
      case 'Diamant':
        return Colors.blue.shade300;
      default:
        return const Color(0xFFCD7F32);
    }
  }

  Widget _buildPendingRequestsSection() {
    if (_pendingRequests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              const Text(
                "Invitations en attente",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryRed,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${_pendingRequests.length}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._pendingRequests.map((request) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.orange,
                  child: Text(
                    (request['fromUserName'] as String?)?.isNotEmpty == true
                        ? (request['fromUserName'] as String)[0].toUpperCase()
                        : 'A',
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
                        request['fromUserName'] ?? 'Ami',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Vous a envoyé une invitation d'ami",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _acceptInvitation(
                        request['notificationId'] ?? '',
                        request['fromUserId'] ?? '',
                      ),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text("Accepter"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _rejectInvitation(
                        request['notificationId'] ?? '',
                        request['fromUserId'] ?? '',
                      ),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text("Refuser"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
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
            "Inviter des amis",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryRed,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (value) {
              _searchFriends(value);
            },
            decoration: InputDecoration(
              hintText: "Rechercher par nom ou email...",
              prefixIcon: const Icon(Icons.search, color: primaryRed),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                          _isSearching = false;
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryRed),
              ),
            ),
          ),
          if (_isSearching)
            const SizedBox(height: 12),
          if (_isSearching)
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: _searchResults.isEmpty
                  ? const Center(
                      child: Text(
                        "Aucun utilisateur trouvé",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getLeagueColor(user['league']),
                            child: Text(
                              user['avatar'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            user['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            user['email'],
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          trailing: ElevatedButton.icon(
                            onPressed: () => _sendFriendRequest(user),
                            icon: const Icon(Icons.person_add, size: 16),
                            label: const Text("Inviter"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryRed,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        );
                      },
                    ),
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people, color: primaryRed),
              const SizedBox(width: 8),
              Text(
                "Mes Amis (${_friends.length})",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_friends.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Aucun ami pour le moment",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Utilisez la barre de recherche pour ajouter des amis !",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _friends.length,
              itemBuilder: (context, index) {
                final friend = _friends[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bgGrey,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Photo de profil ou avatar
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primaryRed.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: friend['hasProfileImage'] == true && friend['profileImage'] != null
                              ? _buildFriendProfileImage(friend['profileImage'])
                              : _buildFriendDefaultAvatar(friend),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Informations de l'ami
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    friend['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                // Indicateur de statut en ligne
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: friend['isOnline'] == true ? Colors.green : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // XP et niveau
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getLevelColor(friend['level']),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "${friend['xp']} XP",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    friend['level'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
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
                );
              },
            ),
        ],
      ),
    );
  }

  // Widget pour la photo de profil de l'ami
  Widget _buildFriendProfileImage(String? profileImage) {
    if (profileImage == null || profileImage.isEmpty) {
      return Container(color: Colors.grey.shade200);
    }
    
    try {
      if (profileImage.startsWith('data:image')) {
        final base64String = profileImage.split(',')[1];
        final imageBytes = base64Decode(base64String);
        return Image.memory(
          imageBytes,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(color: Colors.grey.shade200);
          },
        );
      }
    } catch (e) {
      print('Erreur lors de l\'affichage de la photo de l\'ami: $e');
      return Container(color: Colors.grey.shade200);
    }
    
    return Container(color: Colors.grey.shade200);
  }

  // Widget pour l'avatar par défaut de l'ami
  Widget _buildFriendDefaultAvatar(Map<String, dynamic> friend) {
    final name = friend['name']?.toString() ?? 'A';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'A';
    
    return Container(
      color: primaryRed.withOpacity(0.1),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: primaryRed,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Obtenir la couleur du niveau
  Color _getLevelColor(String? level) {
    switch (level?.toLowerCase()) {
      case 'débutant':
        return Colors.grey;
      case 'intermédiaire':
        return Colors.blue;
      case 'avancé':
        return Colors.purple;
      case 'expert':
        return Colors.orange;
      case 'maître':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Vérifier si l'utilisateur est en ligne (simulation)
  bool _isUserOnline(String userId) {
    // Pour la démo, on simule aléatoirement le statut en ligne
    return DateTime.now().millisecondsSinceEpoch % 3 == 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
        ),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPendingRequestsSection(),
            const SizedBox(height: 16),
            _buildSearchSection(),
            const SizedBox(height: 16),
            _buildFriendsSection(),
          ],
        ),
      ),
    );
  }
}
