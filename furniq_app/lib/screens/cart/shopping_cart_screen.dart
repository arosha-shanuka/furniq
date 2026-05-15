import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/cart_item_model.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../routes/app_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/custom_button.dart';

class ShoppingCartScreen extends StatefulWidget {
  const ShoppingCartScreen({super.key});

  @override
  State<ShoppingCartScreen> createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends State<ShoppingCartScreen> {
  bool _isCheckingOut = false;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      await cartProvider.loadCart(authProvider.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    if (!authProvider.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shopping Cart')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_cart_outlined, size: 100, color: AppColors.textSecondary),
                const SizedBox(height: 24),
                const Text('Please sign in to view your cart', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Sign In',
                  onPressed: () => Navigator.pushNamed(context, AppRouter.signIn),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Shopping Cart')),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, _) {
          if (cartProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cartProvider.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_cart_outlined, size: 100, color: AppColors.textSecondary),
                    const SizedBox(height: 24),
                    const Text('Your cart is empty', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Start Shopping',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartProvider.items.length,
                  itemBuilder: (context, index) {
                    return _buildCartItem(
                      context,
                      cartProvider.items[index],
                      authProvider.user!.id,
                    );
                  },
                ),
              ),
              _buildSummary(context, cartProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItem item, String userId) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.cardBackground,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.productImage,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.image),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(item.material, style: AppTextStyles.caption),
                      if (item.selectedColorName != null && item.selectedColorHex != null) ...[
                        const Text(' • ', style: AppTextStyles.caption),
                        _buildColorDot(item.selectedColorHex!),
                        const SizedBox(width: 4),
                        Text(item.selectedColorName!, style: AppTextStyles.caption),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Formatters.currency(item.unitPrice),
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildQuantityButton(
                        icon: Icons.remove,
                        onPressed: () => cartProvider.decrementQuantity(userId, item.id),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('${item.quantity}', style: AppTextStyles.bodyMedium),
                      ),
                      _buildQuantityButton(
                        icon: Icons.add,
                        onPressed: () => cartProvider.incrementQuantity(userId, item.id),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () {
                cartProvider.removeItem(userId, item.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: IconButton(
        icon: Icon(icon, size: 16),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSummary(BuildContext context, CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', Formatters.currency(cartProvider.subtotal)),
          _buildSummaryRow('Shipping', 'FREE', color: AppColors.freeTag),
          const Divider(height: 24),
          _buildSummaryRow(
            'Total',
            Formatters.currency(cartProvider.total),
            isTotal: true,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Proceed to Checkout',
              isLoading: _isCheckingOut,
              onPressed: _isCheckingOut ? null : () async {
                setState(() => _isCheckingOut = true);
                try {
                  bool hasOutOfStock = false;
                  final productProvider = context.read<ProductProvider>();
                  for (var item in cartProvider.items) {
                    final product = await productProvider.getProductById(item.productId);
                    if (product != null && product.stockStatus == StockStatus.outOfStock) {
                      hasOutOfStock = true;
                      break;
                    }
                  }
                  
                  if (hasOutOfStock && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('One or more items in your cart are currently out of stock. Please remove them to proceed.')),
                    );
                  } else if (mounted) {
                    Navigator.pushNamed(context, AppRouter.checkout);
                  }
                } finally {
                  if (mounted) setState(() => _isCheckingOut = false);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false, Color? color}) {
    final textStyle = isTotal
        ? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)
        : AppTextStyles.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textStyle),
          Text(
            value,
            style: textStyle.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildColorDot(String hexColor) {
    Color color = Colors.black;
    try {
      String hex = hexColor.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      color = Color(int.parse(hex, radix: 16));
    } catch (e) {
      // fallback
    }
    
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
    );
  }
}
