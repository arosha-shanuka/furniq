
import '../models/address_model.dart';
import '../screens/home/home_screen.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/products/product_details_screen.dart';
import '../screens/products/category_products_screen.dart';
import '../screens/products/all_products_screen.dart';
import '../screens/cart/shopping_cart_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/checkout/order_confirmation_screen.dart';
import '../screens/orders/order_detail_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/address/address_list_screen.dart';
import '../screens/address/address_form_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/info/terms_privacy_screen.dart';
import '../screens/ar/ar_viewer_screen.dart';
import 'package:flutter/material.dart';

class AppRouter {
  // Route names
  static const String home = '/';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String profile = '/profile';
  static const String productDetails = '/product-details';
  static const String categoryProducts = '/category-products';
  static const String allProducts = '/all-products';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orderConfirmation = '/order-confirmation';
  static const String orderDetail = '/order-detail';
  static const String orders = '/orders';
  static const String addressList = '/address-list';
  static const String addressForm = '/address-form';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String termsPrivacy = '/terms-privacy';
  static const String arViewer = '/ar-viewer';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Extract arguments
    final args = settings.arguments;

    switch (settings.name) {
      case home:
        return _buildRoute(const HomeScreen());
      
      case signIn:
        return _buildRoute(const SignInScreen());
      
      case signUp:
        return _buildRoute(const SignUpScreen());

      case forgotPassword:
        return _buildRoute(const ForgotPasswordScreen());

      case verifyEmail:
        return _buildRoute(const VerifyEmailScreen());
      
      case profile:
        return _buildRoute(const ProfileScreen());
      
      case productDetails:
        return _buildRoute(ProductDetailsScreen(productId: args as String));
      
      case categoryProducts:
        final categoryArgs = args as Map<String, dynamic>;
        return _buildRoute(CategoryProductsScreen(
          categoryId: categoryArgs['categoryId'],
          categoryName: categoryArgs['categoryName'],
        ));
      
      case allProducts:
        final query = args as String?;
        return _buildRoute(AllProductsScreen(initialSearchQuery: query));
      
      case cart:
        return _buildRoute(const ShoppingCartScreen());
      
      case checkout:
        return _buildRoute(const CheckoutScreen());
      
      case orderConfirmation:
        return _buildRoute(OrderConfirmationScreen(orderId: args as String));
      
      case orderDetail:
        return _buildRoute(OrderDetailScreen(orderId: args as String));
      
      case orders:
        return _buildRoute(const OrdersScreen());
      
      case addressList:
        return _buildRoute(const AddressListScreen());
      
      case addressForm:
        return _buildRoute(AddressFormScreen(address: args as Address?));
      
      case notifications:
        return _buildRoute(const NotificationsScreen());
      
      case AppRouter.settings:
        return _buildRoute(const SettingsScreen());
      
      case termsPrivacy:
        return _buildRoute(const TermsPrivacyScreen());
      
      case arViewer:
        final arArgs = args as Map<String, dynamic>;
        return _buildRoute(ARViewerScreen(
          productId: arArgs['productId'],
          arModelUrl: arArgs['arModelUrl'],
          availableColors: arArgs['availableColors'] ?? [],
          selectedColor: arArgs['selectedColor'] ?? '',
        ));
      
      default:
        return _buildRoute(const Scaffold(
          body: Center(child: Text('Route not found')),
        ));
    }
  }

  static MaterialPageRoute _buildRoute(Widget screen) {
    return MaterialPageRoute(builder: (_) => screen);
  }
}
