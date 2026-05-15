import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    // In a real app with stream OrderProvider, we might subscribe here.
    // For now, we'll fetch once or listen to the provider.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().listenToOrder(widget.orderId);
    });
  }
  
  @override
  void dispose() {
    // We should probably cancel the stream subscription in the provider,
    // but the provider might manage it. Let's add a clearCurrentOrder to provider later.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, _) {
          final order = provider.currentOrder;
          
          if (provider.isLoading && order == null) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        order.orderNumber, 
                        style: AppTextStyles.h4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _getStatusColor(order.status)),
                      ),
                      child: Text(
                        order.statusText.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(order.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Placed on ${Formatters.date(order.createdAt)}',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),

                // Order Status Timeline
                const Text('Order Tracking', style: AppTextStyles.h4),
                const SizedBox(height: 24),
                _buildTimeline(order.status),
                
                const SizedBox(height: 32),

                // Shipping Details
                const Text('Shipping Address', style: AppTextStyles.h4),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.shippingAddress.fullName, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(order.shippingAddress.fullAddress, style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(order.shippingAddress.phone, style: AppTextStyles.bodyMedium),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Items List
                const Text('Items', style: AppTextStyles.h4),
                const SizedBox(height: 16),
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = order.items[index];
                      return ListTile(
                        title: Text(item.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                        subtitle: Text('Qty: ${item.quantity}'),
                        trailing: Text(Formatters.currency(item.lineTotal), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Order Summary
                const Text('Payment Summary', style: AppTextStyles.h4),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildSummaryRow('Subtotal', order.subtotal),
                        _buildSummaryRow('Delivery Fee', order.deliveryFee),
                        _buildSummaryRow('Tax', order.tax),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(Formatters.currency(order.total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                order.paymentMethod == PaymentMethod.onlinePayment ? Icons.credit_card : Icons.money,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(order.paymentMethodText, style: AppTextStyles.bodyMedium),
                              ),
                              Text(
                                order.paymentStatus.name.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: order.paymentStatus == PaymentStatus.paid ? AppColors.success : AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          Text(Formatters.currency(value), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTimeline(OrderStatus currentStatus) {
    if (currentStatus == OrderStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel, color: AppColors.error),
            SizedBox(width: 12),
            Text('This order has been cancelled.', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    final steps = [
      {'status': OrderStatus.pending, 'title': 'Order Placed', 'icon': Icons.receipt_long},
      {'status': OrderStatus.processing, 'title': 'Processing', 'icon': Icons.inventory_2},
      {'status': OrderStatus.shipped, 'title': 'Shipped', 'icon': Icons.local_shipping},
      {'status': OrderStatus.delivered, 'title': 'Delivered', 'icon': Icons.home},
    ];

    int currentIndex = steps.indexWhere((s) => s['status'] == currentStatus);
    if (currentIndex == -1) currentIndex = 0; // Fallback

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isCompleted = index <= currentIndex;
        final isCurrent = index == currentIndex;
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.primary : AppColors.border,
                    shape: BoxShape.circle,
                    boxShadow: isCurrent ? [
                      BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, spreadRadius: 2)
                    ] : null,
                  ),
                  child: Icon(
                    step['icon'] as IconData,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: isCompleted && index < currentIndex ? AppColors.primary : AppColors.border,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  step['title'] as String,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: isCurrent ? FontWeight.bold : (isCompleted ? FontWeight.w600 : FontWeight.normal),
                    color: isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return AppColors.pending;
      case OrderStatus.processing: return AppColors.processing;
      case OrderStatus.shipped: return AppColors.info;
      case OrderStatus.delivered: return AppColors.success;
      case OrderStatus.cancelled: return AppColors.error;
    }
  }
}
