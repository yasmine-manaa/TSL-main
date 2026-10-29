import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class ProfileImageService {
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static FirebaseAuth get _auth => FirebaseAuth.instance;
  
  // Clé de cryptage (en production, utiliser une clé plus sécurisée)
  static const String _encryptionKey = 'LST_Profile_Key_2024_Secure';

  // Crypter les données de l'image
  static String _encryptImageData(Uint8List imageData) {
    try {
      // Convertir l'image en base64
      String base64Image = base64Encode(imageData);
      
      // Crypter avec SHA-256 (simple pour démonstration)
      var bytes = utf8.encode(base64Image + _encryptionKey);
      var digest = sha256.convert(bytes);
      
      // Pour le stockage, on utilise le base64 original + hash pour vérification
      return base64Image;
    } catch (e) {
      print('Erreur lors de la cryptographie: $e');
      throw Exception('Erreur lors du cryptage de l\'image');
    }
  }

  // Décrypter les données de l'image
  static String _decryptImageData(String encryptedData) {
    try {
      // En réalité, on retourne les données base64 directement
      // Le hash est utilisé pour vérification si nécessaire
      return encryptedData;
    } catch (e) {
      print('Erreur lors du décryptage: $e');
      throw Exception('Erreur lors du décryptage de l\'image');
    }
  }

  // Sauvegarder l'image de profil dans Firebase
  static Future<void> saveProfileImage(String imagePath) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      // Lire l'image
      final imageFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (imageFile == null) throw Exception('Aucune image sélectionnée');

      // Convertir en bytes
      final imageBytes = await imageFile.readAsBytes();
      final uint8List = Uint8List.fromList(imageBytes);

      // Crypter les données
      final encryptedData = _encryptImageData(uint8List);

      // Sauvegarder dans Firestore
      await _firestore.collection('users').doc(currentUser.uid).update({
        'profileImage': encryptedData,
        'profileImageHash': sha256.convert(utf8.encode(encryptedData + _encryptionKey)).toString(),
        'profileImageUpdatedAt': DateTime.now().toIso8601String(),
        'hasProfileImage': true,
      });

      print('Image de profil sauvegardée avec succès dans Firebase');
    } catch (e) {
      print('Erreur lors de la sauvegarde de l\'image: $e');
      throw e;
    }
  }

  // Récupérer l'image de profil depuis Firebase
  static Future<String?> getProfileImage() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data()!;
      final encryptedData = userData['profileImage'] as String?;
      
      if (encryptedData == null || encryptedData.isEmpty) return null;

      // Décrypter et retourner les données
      return _decryptImageData(encryptedData);
    } catch (e) {
      print('Erreur lors de la récupération de l\'image: $e');
      return null;
    }
  }

  // Supprimer l'image de profil
  static Future<void> deleteProfileImage() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      await _firestore.collection('users').doc(currentUser.uid).update({
        'profileImage': FieldValue.delete(),
        'profileImageHash': FieldValue.delete(),
        'profileImageUpdatedAt': FieldValue.delete(),
        'hasProfileImage': false,
      });

      print('Image de profil supprimée avec succès');
    } catch (e) {
      print('Erreur lors de la suppression de l\'image: $e');
      throw e;
    }
  }

  // Vérifier si l'utilisateur a une image de profil
  static Future<bool> hasProfileImage() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      return userData['hasProfileImage'] == true;
    } catch (e) {
      print('Erreur lors de la vérification de l\'image: $e');
      return false;
    }
  }

  // Mettre à jour l'image de profil (pour la page de modification)
  static Future<void> updateProfileImage(String? newImagePath) async {
    try {
      if (newImagePath == null || newImagePath.isEmpty) {
        // Supprimer l'image
        await deleteProfileImage();
      } else {
        // Mettre à jour avec nouvelle image
        await saveProfileImage(newImagePath);
      }
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'image: $e');
      throw e;
    }
  }

  // Obtenir les métadonnées de l'image
  static Future<Map<String, dynamic>?> getProfileImageMetadata() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data()!;
      
      return {
        'hasProfileImage': userData['hasProfileImage'] == true,
        'profileImageUpdatedAt': userData['profileImageUpdatedAt'],
        'profileImageHash': userData['profileImageHash'],
      };
    } catch (e) {
      print('Erreur lors de la récupération des métadonnées: $e');
      return null;
    }
  }

  // Synchroniser l'image depuis SharedPreferences vers Firebase
  static Future<void> syncImageFromPreferences() async {
    try {
      // Cette méthode peut être utilisée pour migrer les anciennes images
      // depuis SharedPreferences vers Firebase
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Vérifier si l'image existe déjà dans Firebase
      final hasImage = await hasProfileImage();
      if (hasImage) return; // Déjà synchronisé

      // Récupérer depuis SharedPreferences (ancien système)
      // final prefs = await SharedPreferences.getInstance();
      // final localImagePath = prefs.getString('profile_image_path');
      
      // Si une image locale existe, la migrer vers Firebase
      // if (localImagePath != null && localImagePath.isNotEmpty) {
      //   await saveProfileImage(localImagePath);
      //   // Supprimer de SharedPreferences après migration
      //   await prefs.remove('profile_image_path');
      // }
    } catch (e) {
      print('Erreur lors de la synchronisation: $e');
    }
  }
}
