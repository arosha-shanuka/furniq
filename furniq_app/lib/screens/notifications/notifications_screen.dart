import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        Provider.of<NotificationProvider>(context, listen: false)
            .listenToNotifications(authProvider.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer2<NotificationProvider, AuthProvider>(
            builder: (context, notifProvider, authProvider, _) {
              if (notifProvider.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () {
                  if (authProvider.user != null) {
                    notifProvider.markAllAsRead(authProvider.user!.id);
                  }
                },
                child: const Text('Mark all as read', style: TextStyle(color: AppColors.textLight)),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          final notifications = provider.notifications;
          
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_off_outlined, size: 80, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text('No notifications yet', style: AppTextStyles.h4),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final isRead = notif.read;
              
              return Dismissible(
                key: Key(notif.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                  provider.markAsRead(notif.id);
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: AppColors.success,
                  child: const Icon(Icons.check, color: Colors.white),
                ),
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  color: isRead ? AppColors.surface : AppColors.primary.withOpacity(0.05),
                  child: ListTile(
                    onTap: () {
                      if (!isRead) {
                        provider.markAsRead(notif.id);
                      }
                      if (notif.orderId != null) {
                        Navigator.pushNamed(context, '/order-detail', arguments: notif.orderId);
                      }
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        notif.orderId != null ? Icons.receipt_long : Icons.notifications,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      notif.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notif.message),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimeAgo(notif.createdAt),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
