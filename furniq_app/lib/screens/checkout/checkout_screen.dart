import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../models/address_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/address_provider.dart';
import '../../routes/app_router.dart';
import '../../services/payment_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();

  PaymentMethod _selectedPaymentMethod = PaymentMethod.cashOnDelivery;
  bool _isProcessingPayment = false;
  bool _saveAddress = true; // checkbox to save address for next time
  Address? _selectedAddress; // currently selected saved address
  bool _useNewAddress = false;

  final PaymentService _paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
    _prefillUserData();
    _loadSavedAddresses();
  }

  void _prefillUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn) {
      _nameController.text = authProvider.user!.name;
      _emailController.text = authProvider.user!.email;
    }
  }

  Future<void> _loadSavedAddresses() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) return;

    final addressProvider = Provider.of<AddressProvider>(context, listen: false);
    await addressProvider.loadAddresses(authProvider.user!.id);

    debugPrint('CHECKOUT: Loaded ${addressProvider.addresses.length} saved addresses');

    if (mounted && addressProvider.addresses.isNotEmpty) {
      final defaultAddr = addressProvider.defaultAddress ?? addressProvider.addresses.first;
      debugPrint('CHECKOUT: Pre-filling from address: ${defaultAddr.label} — ${defaultAddr.street}');
      setState(() {
        _selectedAddress = defaultAddr;
        _useNewAddress = false;
        _fillFromAddress(defaultAddr);
      });
    }
  }

  void _fillFromAddress(Address address) {
    _nameController.text = address.fullName;
    _phoneController.text = address.phone;
    _streetController.text = address.street;
    _cityController.text = address.city;
    _postalCodeController.text = address.postalCode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────
  // Place Order — main action handler
  // ──────────────────────────────────────────────────────────

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    // Save the address if checkbox is checked and user entered a new one
    if (_saveAddress && (_useNewAddress || _selectedAddress == null)) {
      await _saveNewAddress();
    }

    if (_selectedPaymentMethod == PaymentMethod.onlinePayment) {
      await _placeOrderWithStripe();
    } else {
      await _placeOrderCashOnDelivery();
    }
  }

  Future<void> _saveNewAddress() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final addressProvider = Provider.of<AddressProvider>(context, listen: false);

    if (!authProvider.isLoggedIn) return;

    final address = Address(
      id: '',
      userId: authProvider.user!.id,
      label: 'Home',
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      street: _streetController.text.trim(),
      city: _cityController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      isDefault: addressProvider.addresses.isEmpty, // first address = default
      createdAt: DateTime.now(),
    );

    await addressProvider.createAddress(address);
  }

  /// Cash on Delivery — creates order immediately without any payment processing.
  Future<void> _placeOrderCashOnDelivery() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    final order = _buildOrder(
      paymentStatus: PaymentStatus.notPaid,
    );

    final createdOrder = await orderProvider.createOrder(order);

    if (createdOrder != null && mounted) {
      await cartProvider.clearCart(authProvider.user!.id);
      _navigateToConfirmation(createdOrder.id);
    } else if (orderProvider.error != null && mounted) {
      _showPaymentErrorDialog("Failed to save order: ${orderProvider.error}");
    } else if (mounted) {
      _showPaymentErrorDialog("Unknown error occurred while creating the order.");
    }
  }

  /// Stripe — creates PaymentIntent → presents Payment Sheet → creates order on success.
  Future<void> _placeOrderWithStripe() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    setState(() => _isProcessingPayment = true);

    try {
      // 1. Process payment via Stripe Payment Sheet
      final paymentIntentId = await _paymentService.processPayment(
        amount: cartProvider.total,
        customerEmail: _emailController.text.trim(),
      );

      // 2. Payment succeeded — create the order in Firestore
      final order = _buildOrder(
        paymentStatus: PaymentStatus.paid,
        stripePaymentIntentId: paymentIntentId,
      );

      final createdOrder = await orderProvider.createOrder(order);

      if (createdOrder != null && mounted) {
        await cartProvider.clearCart(authProvider.user!.id);
        _navigateToConfirmation(createdOrder.id);
      } else if (orderProvider.error != null) {
        throw Exception("Failed to save order: ${orderProvider.error}");
      } else {
        throw Exception("Unknown error occurred while creating the order.");
      }
    } on Exception catch (e, stackTrace) {
      if (!mounted) return;

      debugPrint('CHECKOUT ERROR: $e');
      debugPrint('STACKTRACE: $stackTrace');

      final message = e.toString().replaceFirst('Exception: ', '');

      // Payment cancelled — don't show an error, just let user retry
      if (message.contains('cancelled') || message.contains('canceled')) {
        setState(() => _isProcessingPayment = false);
        return;
      }

      // Show error dialog for actual failures
      _showPaymentErrorDialog(message);
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  /// Builds an Order object from the current form state.
  Order _buildOrder({
    required PaymentStatus paymentStatus,
    String? stripePaymentIntentId,
  }) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: authProvider.user!.id,
      items: cartProvider.items.map((item) {
        return OrderItem(
          productId: item.productId,
          name: item.productName,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          lineTotal: item.totalPrice,
          selectedColorHex: item.selectedColorHex,
          selectedColorName: item.selectedColorName,
        );
      }).toList(),
      subtotal: cartProvider.subtotal,
      tax: cartProvider.tax,
      deliveryFee: cartProvider.deliveryFee,
      total: cartProvider.total,
      paymentMethod: _selectedPaymentMethod,
      status: OrderStatus.pending,
      paymentStatus: paymentStatus,
      createdAt: DateTime.now(),
      shippingAddress: ShippingAddress(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        street: _streetController.text.trim(),
        city: _cityController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
      ),
      stripePaymentIntentId: stripePaymentIntentId,
    );
  }

  void _navigateToConfirmation(String orderId) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRouter.orderConfirmation,
      (route) => false,
      arguments: orderId,
    );
  }

  void _showPaymentErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 24),
            const SizedBox(width: 8),
            const Text('Payment Failed'),
          ],
        ),
        content: Text(
          message,
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('Checkout')),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                            Icons.person_outline, 'Customer Information'),
                        const SizedBox(height: 12),
                        _buildCustomerInfoCard(),
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                            Icons.location_on_outlined, 'Delivery Address'),
                        const SizedBox(height: 12),
                        _buildSavedAddressSelector(),
                        const SizedBox(height: 12),
                        _buildAddressCard(),
                        const SizedBox(height: 24),
                        _buildSectionHeader(Icons.payment, 'Payment Method'),
                        const SizedBox(height: 12),
                        _buildPaymentMethodCard(),
                        const SizedBox(height: 24),
                        Text('Order Summary',
                            style: AppTextStyles.bodyLarge
                                .copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        _buildOrderSummary(),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),

        // ── Full-screen loading overlay while Stripe processes ──
        if (_isProcessingPayment)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Processing Payment…',
                      style: AppTextStyles.bodyLarge
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please wait, do not close the app',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // Widgets
  // ──────────────────────────────────────────────────────────

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title,
            style:
                AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildCustomerInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CustomTextField(
              controller: _nameController,
              hintText: 'Enter your full name',
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _emailController,
              hintText: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _phoneController,
              hintText: 'Enter your phone number',
              keyboardType: TextInputType.phone,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
          ],
        ),
      ),
    );
  }

  /// Horizontal scrollable chips for saved addresses.
  Widget _buildSavedAddressSelector() {
    return Consumer<AddressProvider>(
      builder: (context, addressProvider, _) {
        if (addressProvider.addresses.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Use a saved address',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ...addressProvider.addresses.map((addr) {
                    final isSelected = !_useNewAddress && _selectedAddress?.id == addr.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              addr.label.toLowerCase() == 'office'
                                  ? Icons.business_outlined
                                  : Icons.home_outlined,
                              size: 16,
                              color: isSelected ? AppColors.textLight : AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(addr.label),
                          ],
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.textLight : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedAddress = addr;
                              _useNewAddress = false;
                              _fillFromAddress(addr);
                            });
                          }
                        },
                      ),
                    );
                  }),
                  // "New Address" chip
                  ChoiceChip(
                    label: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 16),
                        SizedBox(width: 4),
                        Text('New'),
                      ],
                    ),
                    selected: _useNewAddress,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: _useNewAddress ? AppColors.textLight : AppColors.textPrimary,
                      fontWeight: _useNewAddress ? FontWeight.w600 : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _useNewAddress = true;
                          _selectedAddress = null;
                          _streetController.clear();
                          _cityController.clear();
                          _postalCodeController.clear();
                          _phoneController.clear();
                          // Re-fill name from auth
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          if (authProvider.isLoggedIn) {
                            _nameController.text = authProvider.user!.name;
                          }
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CustomTextField(
              controller: _streetController,
              hintText: 'Enter your street address',
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _cityController,
                    hintText: 'City',
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: _postalCodeController,
                    hintText: 'Postal code',
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            // Show "Save this address" checkbox only for new addresses
            if (_useNewAddress || _selectedAddress == null) ...[
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _saveAddress,
                onChanged: (val) => setState(() => _saveAddress = val ?? true),
                title: const Text('Save this address for next time'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Cash on Delivery ──
            RadioListTile<PaymentMethod>(
              value: PaymentMethod.cashOnDelivery,
              groupValue: _selectedPaymentMethod,
              onChanged: (value) =>
                  setState(() => _selectedPaymentMethod = value!),
              activeColor: AppColors.primary,
              title: const Text('Cash on Delivery'),
              subtitle: const Text('Pay when you receive your order'),
              secondary: const Icon(Icons.local_shipping_outlined,
                  color: AppColors.primary),
              contentPadding: EdgeInsets.zero,
            ),

            const Divider(height: 1),

            // ── Online Payment (Stripe) ──
            RadioListTile<PaymentMethod>(
              value: PaymentMethod.onlinePayment,
              groupValue: _selectedPaymentMethod,
              onChanged: (value) =>
                  setState(() => _selectedPaymentMethod = value!),
              activeColor: AppColors.primary,
              title: const Text('Pay by Card'),
              subtitle: const Text('Visa, Mastercard, Amex — powered by Stripe'),
              secondary: const Icon(Icons.credit_card, color: AppColors.primary),
              contentPadding: EdgeInsets.zero,
            ),

            // ── Stripe security note — shown when card is selected ──
            if (_selectedPaymentMethod == PaymentMethod.onlinePayment)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF635BFF).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF635BFF).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline,
                        size: 16, color: Color(0xFF635BFF)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your card details are encrypted and processed securely by Stripe. Furniq never sees your card number.',
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFF635BFF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummaryRow(
                    'Subtotal (${cartProvider.itemCount} items)',
                    Formatters.currency(cartProvider.subtotal)),
                _buildSummaryRow('Delivery', 'Free',
                    color: AppColors.freeTag),
                _buildSummaryRow(
                    'Tax (8%)', Formatters.currency(cartProvider.tax)),
                const Divider(height: 24),
                _buildSummaryRow(
                    'Total', Formatters.currency(cartProvider.total),
                    isTotal: true),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isTotal = false, Color? color}) {
    final textStyle = isTotal
        ? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)
        : AppTextStyles.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textStyle),
          Text(value, style: textStyle.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontSize: 16)),
                  Text(
                    Formatters.currency(cartProvider.total),
                    style: AppTextStyles.price,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _selectedPaymentMethod == PaymentMethod.cashOnDelivery
                    ? 'Cash on Delivery'
                    : 'Secure Card Payment via Stripe',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: _selectedPaymentMethod == PaymentMethod.onlinePayment
                      ? 'Pay ${Formatters.currency(cartProvider.total)}'
                      : 'Place Order',
                  onPressed: _isProcessingPayment ? null : _placeOrder,
                  icon: _selectedPaymentMethod == PaymentMethod.onlinePayment
                      ? Icons.credit_card
                      : Icons.check_circle_outline,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
