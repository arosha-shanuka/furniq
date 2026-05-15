import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/notification_provider.dart';
import '../../routes/app_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await orderProvider.loadOrders(authProvider.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (!authProvider.isLoggedIn) {
            return _buildLoggedOutView(context);
          }
          return _buildLoggedInView(context, authProvider);
        },
      ),
    );
  }

  Widget _buildLoggedOutView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.cardBackground,
              child: Icon(Icons.person_outline, size: 60, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Text('Welcome to Furniq', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            Text(
              'Sign in to access your profile, order history, and personalized recommendations.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRouter.signIn);
                },
                child: const Text('Sign In'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRouter.signUp);
                },
                child: const Text('Create Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedInView(BuildContext context, AuthProvider authProvider) {
    final user = authProvider.user!;
    
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary,
            child: Text(
              user.initials,
              style: AppTextStyles.h2.copyWith(color: AppColors.textLight),
            ),
          ),
          const SizedBox(height: 16),
          Text(user.name, style: AppTextStyles.h3),
          Text(user.email, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          if (user.premiumFlag) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Premium Member',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          _buildRecentOrders(context),
          _buildMenuItem(
            icon: Icons.location_on_outlined,
            title: 'Delivery Addresses',
            subtitle: 'Manage your saved addresses',
            onTap: () => Navigator.pushNamed(context, AppRouter.addressList),
          ),
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, _) {
              final unreadCount = notificationProvider.unreadCount;
              return _buildMenuItem(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Manage your notification preferences',
                badge: unreadCount > 0 ? unreadCount.toString() : null,
                onTap: () => Navigator.pushNamed(context, AppRouter.notifications),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'App preferences and privacy',
            onTap: () => Navigator.pushNamed(context, AppRouter.settings),
          ),
          _buildMenuItem(
            icon: Icons.description_outlined,
            title: 'Terms & Privacy',
            subtitle: 'Legal information',
            onTap: () => Navigator.pushNamed(context, AppRouter.termsPrivacy),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton(
              onPressed: () async {
                await authProvider.signOut();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, AppRouter.home, (route) => false);
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 8),
                  Text('Sign Out'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRecentOrders(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        final recentOrder = orderProvider.getRecentOrder();
        
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text('Recent Orders', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, AppRouter.orders),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                if (recentOrder != null) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(recentOrder.orderNumber, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                          Text(Formatters.date(recentOrder.createdAt), style: AppTextStyles.caption),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(Formatters.currency(recentOrder.total), style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(recentOrder.statusText),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              recentOrder.statusText,
                              style: const TextStyle(color: AppColors.textLight, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ] else ...[
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text('No orders yet', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textSecondary),
        title: Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: AppTextStyles.caption),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              )
            : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.pending;
      case 'processing':
        return AppColors.processing;
      case 'delivered':
        return AppColors.delivered;
      default:
        return AppColors.textSecondary;
    }
  }
}
