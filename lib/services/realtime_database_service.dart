import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RealtimeDatabaseService {
  static FirebaseDatabase? _database;
  static DatabaseReference? _usersRef;
  static DatabaseReference? _detectionsRef;
  
  // Initialize with custom database URL
  static void initialize() {
    _database = FirebaseDatabase.instance;
    _database!.databaseURL = 'https://tsl-ai-default-rtdb.firebaseio.com/';
    _usersRef = _database!.ref('users');
    _detectionsRef = _database!.ref('detections');
  }

  static FirebaseDatabase get _db => _database!;
  static DatabaseReference get _users => _usersRef!;
  static DatabaseReference get _detections => _detectionsRef!;

  // Save user data to Realtime Database
  static Future<void> saveUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _users.child(userId).set(data);
    } catch (e) {
      throw Exception('Failed to save user data: $e');
    }
  }

  // Get user data from Realtime Database
  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final snapshot = await _users.child(userId).get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Save detection result
  static Future<void> saveDetection(String userId, String sign, double confidence) async {
    try {
      final detectionData = {
        'userId': userId,
        'sign': sign,
        'confidence': confidence,
        'timestamp': ServerValue.timestamp,
      };
      await _detections.push().set(detectionData);
    } catch (e) {
      throw Exception('Failed to save detection: $e');
    }
  }

  // Get detection history for a user
  static Stream<DatabaseEvent> getUserDetections(String userId) {
    return _detections
        .orderByChild('userId')
        .equalTo(userId)
        .onValue;
  }

  // Update user profile
  static Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      await _users.child(userId).update(updates);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Get current user ID
  static String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // Check if user is authenticated
  static bool get isAuthenticated => FirebaseAuth.instance.currentUser != null;
}
