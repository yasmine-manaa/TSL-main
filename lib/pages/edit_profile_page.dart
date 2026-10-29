import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../services/user_service.dart';
import '../services/profile_image_service.dart';
import 'login_page.dart';

const Color primaryRed = Color(0xFFE60012);
const Color bgGrey = Color(0xFFF5F5F5);

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  bool _obscurePassword = true;
  bool _obscureNewPassword = true;
  
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _birthDateController = TextEditingController();

  String? _profileImagePath;
  bool _hasProfileImage = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadProfileImage();
  }

  Future<void> _loadUserInfo() async {
    try {
      final userInfo = await UserService.getUserInfo();
      
      // Charger la date de naissance depuis SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final birthDate = prefs.getString('birth_date') ?? '';
      
      final nameParts = userInfo['name']?.split(' ') ?? [];
      setState(() {
        _firstNameController.text = nameParts.isNotEmpty ? nameParts[0] : '';
        _lastNameController.text = nameParts.length > 1 
            ? nameParts.sublist(1).join(' ') 
            : '';
        _emailController.text = userInfo['email'] ?? '';
        _birthDateController.text = birthDate;
      });
    } catch (e) {
      print('Erreur lors du chargement des infos utilisateur: $e');
    }
  }

  Future<void> _loadProfileImage() async {
    try {
      // Utiliser le nouveau service Firebase
      final imageData = await ProfileImageService.getProfileImage();
      final hasImage = await ProfileImageService.hasProfileImage();
      
      if (mounted) {
        setState(() {
          _profileImagePath = imageData;
          _hasProfileImage = hasImage;
        });
      }
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

  // Afficher les options d'image
  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera, color: primaryRed),
                title: const Text('Prendre une photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: primaryRed),
                title: const Text('Choisir depuis la galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Supprimer la photo'),
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteProfileImage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Supprimer l'image de profil
  Future<void> _deleteProfileImage() async {
    try {
      await ProfileImageService.deleteProfileImage();
      await _loadProfileImage();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image de profil supprimée avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Erreur lors de la suppression de l\'image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Prendre ou choisir une image
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.front,
      );

      if (pickedFile != null) {
        // Sauvegarder dans Firebase avec cryptage
        await ProfileImageService.saveProfileImage(pickedFile.path);
        
        // Recharger l'image depuis Firebase
        await _loadProfileImage();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image de profil mise à jour avec succès dans Firebase'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucune image sélectionnée'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Erreur lors de la sélection de l\'image: $e');
      if (mounted) {
        String errorMessage = 'Erreur lors de la sélection de l\'image';
        if (e.toString().contains('permission')) {
          errorMessage = 'Permission d\'accès à la caméra/galerie refusée';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Erreur de connexion à Firebase';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Construire l'avatar par défaut
  Widget _buildDefaultAvatar() {
    return CircleAvatar(
      radius: 40,
      backgroundColor: Colors.grey.shade300,
      child: Icon(
        Icons.person,
        size: 40,
        color: Colors.grey.shade600,
      ),
    );
  }

  // Widget pour construire l'image de profil
  Widget _buildProfileImage() {
    if (_profileImagePath != null && _profileImagePath!.isNotEmpty) {
      try {
        // Vérifier si c'est du base64
        if (_profileImagePath!.startsWith('data:image')) {
          final base64String = _profileImagePath!.split(',')[1];
          final imageBytes = base64Decode(base64String);
          
          return CircleAvatar(
            radius: 40,
            backgroundImage: MemoryImage(imageBytes),
            backgroundColor: Colors.transparent,
          );
        }
      } catch (e) {
        print('Erreur lors du chargement de l\'image: $e');
      }
    }
    
    return _buildDefaultAvatar();
  }

  Future<void> _saveProfile() async {
    if (_firstNameController.text.trim().isEmpty || 
        _lastNameController.text.trim().isEmpty || 
        _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs obligatoires"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fullName = "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}";
      final currentEmail = _emailController.text.trim();
      
      // Sauvegarder la date de naissance
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('birth_date', _birthDateController.text.trim());
      
      // Mettre à jour les informations utilisateur
      await UserService.updateUserInfo(
        userName: fullName,
        email: currentEmail,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profil mis à jour avec succès"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du profil: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la mise à jour: ${e.toString()}"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Modifier le profil",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Image Section
            GestureDetector(
              onTap: _showImageOptions,
              child: _buildProfileImage(),
            ),
            const SizedBox(height: 20),
            
            // Form Fields
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: "Prénom",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: "Nom",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _birthDateController,
              decoration: InputDecoration(
                labelText: "Date de naissance",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 30),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Enregistrer",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
