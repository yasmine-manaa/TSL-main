import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';
import '../widgets/navigation_wrapper.dart';
import 'login_page.dart';

const Color primaryRed = Color(0xFFE60012);
const Color bgGrey = Color(0xFFF5F5F5);
const Color lightRed = Color(0xFFFFE5E5);

// Clé globale pour l'input file
final GlobalKey<_SettingsPageState> settingsKey = GlobalKey<_SettingsPageState>();

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _profileImagePath;
  bool _hasProfileImage = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final userData = await UserService.getUserData();
    if (userData != null) {
      setState(() {
        _nameController.text = userData['name'] ?? '';
        _emailController.text = userData['email'] ?? '';
      });
    }
    
    // Charger l'image de profil sauvegardée
    await _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileImagePath = prefs.getString('profile_image_path');
      final profileImageBase64 = prefs.getString('profile_image_base64');
      
      if (profileImagePath != null && profileImagePath.isNotEmpty) {
        setState(() {
          _profileImagePath = profileImagePath;
          _hasProfileImage = true;
        });
      } else if (profileImageBase64 != null && profileImageBase64.isNotEmpty) {
        setState(() {
          _profileImagePath = profileImageBase64;
          _hasProfileImage = true;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement de l\'image de profil: $e');
    }
  }

  // Widget pour l'avatar par défaut
  Widget _buildDefaultAvatar() {
    return Text(
      _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'U',
      style: const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: primaryRed,
      ),
    );
  }

  // Méthode pour sélectionner une image de profil depuis le PC (compatible web)
  Future<void> _pickProfileImage() async {
    try {
      // Créer un input file caché
      final html.InputElement fileInput = html.InputElement(type: 'file');
      fileInput.accept = 'image/*';
      
      // Écouter le changement de fichier
      fileInput.onChange.listen((e) async {
        final files = fileInput.files;
        if (files != null && files.isNotEmpty) {
          final file = files[0];
          final reader = html.FileReader();
          
          reader.onLoadEnd.listen((event) async {
            if (reader.readyState == html.FileReader.DONE) {
              final result = reader.result as String;
              
              // Sauvegarder l'image en base64
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('profile_image_base64', result);
              
              setState(() {
                _profileImagePath = result;
                _hasProfileImage = true;
              });
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Image de profil mise à jour avec succès"),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          });
          
          reader.readAsDataUrl(file);
        }
      });
      
      // Cliquer sur l'input file pour ouvrir la boîte de dialogue
      fileInput.click();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la sélection de l'image: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Méthode pour supprimer l'image de profil
  Future<void> _removeProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_image_base64');
      
      setState(() {
        _profileImagePath = null;
        _hasProfileImage = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Image de profil supprimée"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la suppression de l'image: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Simuler la mise à jour
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profil mis à jour avec succès!"),
          backgroundColor: Colors.green,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await UserService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationWrapper(
      selectedIndex: 3, // Profile index
      child: Scaffold(
        backgroundColor: bgGrey,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: primaryRed),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: const Text(
            "Paramètres",
            style: TextStyle(
              color: primaryRed,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Section Image de Profil
              GestureDetector(
                onTap: _pickProfileImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: lightRed,
                    borderRadius: BorderRadius.circular(60),
                    border: Border.all(
                      color: primaryRed.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: _hasProfileImage && _profileImagePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(57),
                                child: Image.memory(
                                  base64Decode(_profileImagePath!.split(',')[1]),
                                  width: 114,
                                  height: 114,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildDefaultAvatar();
                                  },
                                ),
                              )
                            : _buildDefaultAvatar(),
                      ),
                      // Icône de caméra pour indiquer qu'on peut cliquer
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: primaryRed,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 10),
              
              // Bouton pour supprimer l'image si elle existe
              if (_hasProfileImage)
                TextButton.icon(
                  onPressed: _removeProfileImage,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    "Supprimer l'image",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              
              const SizedBox(height: 20),
              
              // Profile Form
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      "Modifier le profil",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: "Nom complet",
                        prefixIcon: const Icon(Icons.person, color: primaryRed),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        prefixIcon: const Icon(Icons.email, color: primaryRed),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "Sauvegarder",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Logout button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    "Se déconnecter",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: primaryRed,
                    side: BorderSide(color: primaryRed),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
