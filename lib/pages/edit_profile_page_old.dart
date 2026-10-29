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

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      final userInfo = await UserService.getUserInfo();
      final prefs = await SharedPreferences.getInstance();
      final birthDate = prefs.getString('birth_date') ?? '';
      
      if (mounted) {
        setState(() {
          _firstNameController.text = userInfo['name']?.split(' ').first ?? '';
          _lastNameController.text = userInfo['name']?.split(' ').skip(1).join(' ') ?? '';
          _emailController.text = userInfo['email'] ?? '';
          _birthDateController.text = birthDate;
        });
      }
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
              const Text(
                'Options de l\'image de profil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              if (_hasProfileImage && _profileImagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Supprimer l\'image'),
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfileImage();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: primaryRed),
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

  // Supprimer l'image de profil
  Future<void> _removeProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_image_base64');
      
      if (mounted) {
        setState(() {
          _profileImagePath = null;
          _hasProfileImage = false;
        });
        
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
          const SnackBar(
            content: Text('Erreur lors de la suppression de l\'image'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Prendre ou choisir une image
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      
      // Configuration spécifique pour la caméra web
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
        // Options supplémentaires pour la caméra web
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
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
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

      // Récupérer l'email actuel depuis UserService
      final userInfo = await UserService.getUserInfo();
      final originalEmail = userInfo['email'] ?? '';

      // Si l'email a changé, il faut se déconnecter et se reconnecter
      if (originalEmail != currentEmail && _newPasswordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pour changer l'email, vous devez également définir un nouveau mot de passe"),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Si un nouveau mot de passe est défini
      if (_newPasswordController.text.isNotEmpty) {
        if (_currentPasswordController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Veuillez entrer votre mot de passe actuel"),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        final result = await UserService.updateProfile(
          originalEmail, // Utiliser l'email original pour l'authentification
          fullName,
          _currentPasswordController.text,
          _newPasswordController.text,
        );

        if (mounted) {
          if (result['success'] == true) {
            // Si l'email a changé, mettre à jour localement et forcer la reconnexion
            if (originalEmail != currentEmail) {
              await prefs.setString('user_email', currentEmail);
              await UserService.logout();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Email modifié. Veuillez vous reconnecter."),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginPage()),
                (route) => false,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Profil mis à jour avec succès"),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? "Erreur lors de la mise à jour"),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Mise à jour sans changement de mot de passe (uniquement nom et date de naissance)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profil mis à jour avec succès"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur: ${e.toString()}"),
            backgroundColor: Colors.red,
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
            color: primaryRed,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryRed),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Photo de profil
              GestureDetector(
                onTap: _showImageOptions,
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryRed, width: 3),
                      ),
                      child: ClipOval(
                        child: _hasProfileImage && _profileImagePath != null
                            ? _buildProfileImage()
                            : _buildDefaultAvatar(),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: primaryRed,
                          shape: BoxShape.circle,
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
              const SizedBox(height: 10),
              const Text(
                "Appuyez pour modifier la photo",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 30),

              // Prénom
              TextField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: "Prénom *",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: primaryRed, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Nom
              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: "Nom *",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: primaryRed, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Date de naissance
              TextField(
                controller: _birthDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Date de naissance",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: primaryRed, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        _birthDateController.text = 
                            "${date.day.toString().padLeft(2, '0')}/"
                            "${date.month.toString().padLeft(2, '0')}/"
                            "${date.year}";
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Email
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email *",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: primaryRed, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Section mot de passe
              const Text(
                "Changer le mot de passe (optionnel)",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 15),

              // Mot de passe actuel
              TextField(
                controller: _currentPasswordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Mot de passe actuel",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: primaryRed, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Nouveau mot de passe
              TextField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: "Nouveau mot de passe",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: primaryRed, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Bouton sauvegarder
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Sauvegarder",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
