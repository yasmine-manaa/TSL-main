import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static final ValueNotifier<List<Map<String, dynamic>>> _notifications = ValueNotifier([]);

  static ValueNotifier<List<Map<String, dynamic>>> get notifications => _notifications;

  // Envoyer une notification d'invitation d'ami
  static Future<void> sendFriendInvitation(String fromUserId, String toUserId, String fromUserName) async {
    try {
      final notification = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': 'friend_invitation',
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'fromUserName': fromUserName,
        'message': '$fromUserName vous a envoyé une invitation d\'ami',
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'status': 'pending', // pending, accepted, rejected
      };

      // Ajouter la notification à l'utilisateur destinataire
      await _firestore
          .collection('users')
          .doc(toUserId)
          .collection('notifications')
          .doc(notification['id']?.toString())
          .set(notification);

      // Mettre à jour la liste d'invitations en attente
      await _firestore
          .collection('users')
          .doc(toUserId)
          .collection('friend_requests')
          .doc(fromUserId)
          .set({
        'fromUserId': fromUserId,
        'fromUserName': fromUserName,
        'status': 'pending',
        'timestamp': DateTime.now().toIso8601String(),
      });

      print('Notification d\'invitation envoyée à $toUserId');
    } catch (e) {
      print('Erreur lors de l\'envoi de la notification: $e');
      throw e;
    }
  }

  // Accepter une invitation d'ami
  static Future<void> acceptFriendInvitation(String notificationId, String fromUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('Utilisateur non connecté');
      
      print('Tentative d\'acceptation - NotificationID: $notificationId, FromUserID: $fromUserId');
      
      if (notificationId.isEmpty || fromUserId.isEmpty) {
        throw Exception('ID de notification ou ID utilisateur invalide');
      }

      // Récupérer la notification pour obtenir les détails
      final notificationDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('notifications')
          .doc(notificationId)
          .get();

      if (!notificationDoc.exists) {
        throw Exception('Notification non trouvée');
      }

      final notificationData = notificationDoc.data()!;

      // Mettre à jour le statut de la notification
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({
        'status': 'accepted',
        'isRead': true,
        'acceptedAt': DateTime.now().toIso8601String(),
      });

      // Ajouter l'ami dans la liste de l'utilisateur actuel
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('friends')
          .doc(fromUserId)
          .set({
        'uid': fromUserId,
        'addedAt': DateTime.now().toIso8601String(),
        'status': 'accepted',
      });

      // Ajouter l'utilisateur actuel dans la liste de l'ami (relation bidirectionnelle)
      await _firestore
          .collection('users')
          .doc(fromUserId)
          .collection('friends')
          .doc(currentUser.uid)
          .set({
        'uid': currentUser.uid,
        'addedAt': DateTime.now().toIso8601String(),
        'status': 'accepted',
      });

      // Envoyer une notification à l'ami qui a envoyé l'invitation
      final currentUserDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final currentUserData = currentUserDoc.data()!;
      final currentUserName = currentUserData['name'] ?? 'Utilisateur';

      await _firestore
          .collection('users')
          .doc(fromUserId)
          .collection('notifications')
          .doc(DateTime.now().millisecondsSinceEpoch.toString())
          .set({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': 'friend_accepted',
        'fromUserId': currentUser.uid,
        'toUserId': fromUserId,
        'fromUserName': currentUserName,
        'message': '$currentUserName a accepté votre invitation d\'ami',
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'status': 'accepted',
      });

      print('Invitation d\'ami acceptée avec succès');
    } catch (e) {
      print('Erreur lors de l\'acceptation de l\'invitation: $e');
      throw e;
    }
  }

  // Refuser une invitation d'ami
  static Future<void> rejectFriendInvitation(String notificationId, String fromUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('Utilisateur non connecté');
      
      print('Tentative de refus - NotificationID: $notificationId, FromUserID: $fromUserId');
      
      if (notificationId.isEmpty || fromUserId.isEmpty) {
        throw Exception('ID de notification ou ID utilisateur invalide');
      }

      // Récupérer la notification pour obtenir les détails
      final notificationDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('notifications')
          .doc(notificationId)
          .get();

      if (!notificationDoc.exists) {
        throw Exception('Notification non trouvée');
      }

      // Mettre à jour le statut de la notification
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({
        'status': 'rejected',
        'isRead': true,
        'rejectedAt': DateTime.now().toIso8601String(),
      });

      // Envoyer une notification à l'ami qui a envoyé l'invitation
      final currentUserDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final currentUserData = currentUserDoc.data()!;
      final currentUserName = currentUserData['name'] ?? 'Utilisateur';

      await _firestore
          .collection('users')
          .doc(fromUserId)
          .collection('notifications')
          .doc(DateTime.now().millisecondsSinceEpoch.toString())
          .set({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': 'friend_rejected',
        'fromUserId': currentUser.uid,
        'toUserId': fromUserId,
        'fromUserName': currentUserName,
        'message': '$currentUserName a refusé votre invitation d\'ami',
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'status': 'rejected',
      });

      print('Invitation d\'ami refusée avec succès');
    } catch (e) {
      print('Erreur lors du refus de l\'invitation: $e');
      throw e;
    }
  }

  // Récupérer les notifications de l'utilisateur actuel
  static Future<List<Map<String, dynamic>>> getUserNotifications() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final notificationsSnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .get();

      List<Map<String, dynamic>> notifications = [];
      
      for (var doc in notificationsSnapshot.docs) {
        final notificationData = doc.data();
        notificationData['id'] = doc.id;
        notifications.add(notificationData);
      }

      return notifications;
    } catch (e) {
      print('Erreur lors de la récupération des notifications: $e');
      return [];
    }
  }

  // Récupérer les invitations d'amis en attente
  static Future<List<Map<String, dynamic>>> getPendingFriendRequests() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      // D'abord récupérer les notifications de type friend_invitation non lues
      final notificationsSnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('notifications')
          .where('type', isEqualTo: 'friend_invitation')
          .where('status', isEqualTo: 'pending')
          .get();

      List<Map<String, dynamic>> requests = [];
      
      for (var doc in notificationsSnapshot.docs) {
        final notificationData = doc.data();
        notificationData['id'] = doc.id;
        notificationData['notificationId'] = doc.id;
        notificationData['fromUserId'] = notificationData['fromUserId'];
        
        // Ajouter les informations de l'expéditeur
        if (notificationData['fromUserId'] != null) {
          try {
            final senderDoc = await _firestore
                .collection('users')
                .doc(notificationData['fromUserId'])
                .get();
            
            if (senderDoc.exists) {
              final senderData = senderDoc.data()!;
              notificationData['fromUserName'] = senderData['name'] ?? 'Ami';
            }
          } catch (e) {
            print('Erreur lors de la récupération des infos de l\'expéditeur: $e');
            notificationData['fromUserName'] = 'Ami';
          }
        }
        
        requests.add(notificationData);
      }

      // Trier par timestamp localement
      requests.sort((a, b) {
        final aTime = a['timestamp'] as String?;
        final bTime = b['timestamp'] as String?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime); // ordre décroissant
      });

      print('Invitations en attente trouvées: ${requests.length}');
      for (var request in requests) {
        print('Invitation: ${request['fromUserName']} - ID: ${request['notificationId']} - From: ${request['fromUserId']}');
      }

      return requests;
    } catch (e) {
      print('Erreur lors de la récupération des demandes d\'amis: $e');
      return [];
    }
  }

  // Marquer une notification comme lue
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Erreur lors du marquage de la notification comme lue: $e');
    }
  }

  // Compter les notifications non lues
  static Future<int> getUnreadNotificationsCount() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return 0;

      final unreadSnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      return unreadSnapshot.docs.length;
    } catch (e) {
      print('Erreur lors du comptage des notifications non lues: $e');
      return 0;
    }
  }

  // Écouter les notifications en temps réel
  static Stream<List<Map<String, dynamic>>> listenToNotifications() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // Envoyer une notification de félicitations
  static Future<void> sendCongratulationNotification(String toUserId, String message, {String? badge}) async {
    try {
      final notification = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': 'congratulation',
        'toUserId': toUserId,
        'message': message,
        'badge': badge,
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'status': 'delivered',
      };

      await _firestore
          .collection('users')
          .doc(toUserId)
          .collection('notifications')
          .doc(notification['id']?.toString())
          .set(notification);

      print('Notification de félicitations envoyée à $toUserId');
    } catch (e) {
      print('Erreur lors de l\'envoi de la notification de félicitations: $e');
    }
  }

  // Nettoyer les anciennes notifications
  static Future<void> cleanupOldNotifications() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      
      final oldNotifications = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('notifications')
          .where('timestamp', isLessThan: cutoffDate.toIso8601String())
          .get();

      for (var doc in oldNotifications.docs) {
        await doc.reference.delete();
      }

      print('Anciennes notifications nettoyées');
    } catch (e) {
      print('Erreur lors du nettoyage des anciennes notifications: $e');
    }
  }

  // Obtenir les statistiques de notification
  static Future<Map<String, int>> getNotificationStats() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return {};

      final notificationsSnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('notifications')
          .get();

      int totalCount = notificationsSnapshot.docs.length;
      int unreadCount = 0;
      int invitationsCount = 0;
      int congratulationsCount = 0;

      for (var doc in notificationsSnapshot.docs) {
        final data = doc.data();
        if (data['isRead'] == false) unreadCount++;
        
        switch (data['type']) {
          case 'friend_invitation':
            invitationsCount++;
            break;
          case 'congratulation':
            congratulationsCount++;
            break;
        }
      }

      return {
        'total': totalCount,
        'unread': unreadCount,
        'invitations': invitationsCount,
        'congratulations': congratulationsCount,
      };
    } catch (e) {
      print('Erreur lors de la récupération des statistiques de notification: $e');
      return {};
    }
  }
}
