import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Request permissions and save the FCM token for the user if enabled.
  Future<void> initialize(String userId) async {
    try {
      // 1. Request Permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // 2. Get the token
        String? token = await _messaging.getToken();
        if (token != null) {
          await _saveTokenToFirestore(userId, token);
        }

        // 3. Listen to token refreshes
        _messaging.onTokenRefresh.listen((newToken) {
          _saveTokenToFirestore(userId, newToken);
        });
      } else {
        debugPrint('User declined or has not accepted permission');
      }
    } catch (e) {
      debugPrint('Error initializing push notifications: $e');
    }
  }

  /// Remove the current device's FCM token from Firestore.
  Future<void> removeToken(String userId) async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmTokens': FieldValue.arrayRemove([token]),
        });
      }
      // Also delete it locally so Firebase generates a new one next time
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('Error removing push notification token: $e');
    }
  }

  /// Update the push notification preference in Firestore.
  Future<void> updatePreference(String userId, bool enabled) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'pushNotificationsEnabled': enabled,
      });

      if (!enabled) {
        // If turned off, remove the current token so this device stops receiving pushes
        await removeToken(userId);
      } else {
        // If turned back on, initialize to get a new token and save it
        await initialize(userId);
      }
    } catch (e) {
      debugPrint('Error updating push notification preference: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String userId, String token) async {
    try {
      // Check if user has push notifications enabled before saving token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final enabled = userDoc.data()?['pushNotificationsEnabled'] ?? true;
        if (enabled) {
          await _firestore.collection('users').doc(userId).update({
            'fcmTokens': FieldValue.arrayUnion([token]),
          });
        }
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }
}
