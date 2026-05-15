import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  
  List<NotificationModel> _notifications = [];
  StreamSubscription<List<NotificationModel>>? _subscription;
  
  List<NotificationModel> get notifications => _notifications;
  
  int get unreadCount => _notifications.where((n) => !n.read).length;

  /// Starts listening to notifications for the given user.
  void listenToNotifications(String userId) {
    _subscription?.cancel();
    _subscription = _notificationService.streamNotifications(userId).listen((data) {
      _notifications = data;
      notifyListeners();
    }, onError: (error) {
      debugPrint('Error streaming notifications: $error');
    });
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    // Optimistic update
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].read) {
      _notifications[index] = _notifications[index].copyWith(read: true);
      notifyListeners();
      await _notificationService.markAsRead(notificationId);
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    // Optimistic update
    bool hasUnread = false;
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].read) {
        _notifications[i] = _notifications[i].copyWith(read: true);
        hasUnread = true;
      }
    }
    
    if (hasUnread) {
      notifyListeners();
      await _notificationService.markAllAsRead(userId);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// Clear all local state (e.g. on logout)
  void clear() {
    _notifications = [];
    _subscription?.cancel();
    notifyListeners();
  }
}
