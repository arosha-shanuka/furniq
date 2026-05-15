import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/order_provider.dart';
import '../../routes/app_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _featuredProductsController = PageController();
  Timer? _autoScrollTimer;
  String? _loadedUserId;

  late AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    _loadData();
    _startAutoScroll();
    
    // Listen for auth changes to load data when user is resolved on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authProvider.addListener(_onAuthChanged);
    });
  }

  void _onAuthChanged() async {
    if (!mounted) return;
    if (_authProvider.isLoggedIn && _authProvider.user != null) {
      bool isVerified = await _authProvider.checkEmailVerified();
      if (!mounted) return;
      if (!isVerified) {
        Navigator.pushNamedAndRemoveUntil(context, AppRouter.verifyEmail, (route) => false);
        return;
      }
      
      if (_loadedUserId != _authProvider.user!.id) {
        _loadData();
      }
    } else {
      if (_loadedUserId != null) {
        _loadedUserId = null;
        if (mounted) {
          Provider.of<NotificationProvider>(context, listen: false).clear();
          Provider.of<OrderProvider>(context, listen: false).clear();
          Provider.of<AddressProvider>(context, listen: false).clear();
          Provider.of<CartProvider>(context, listen: false).clear();
        }
      }
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _featuredProductsController.dispose();
    _authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_featuredProductsController.hasClients) {
        final productProvider = Provider.of<ProductProvider>(context, listen: false);
        if (productProvider.featuredProducts.isNotEmpty) {
          final currentPage = _featuredProductsController.page?.round() ?? 0;
          final nextPage = (currentPage + 1) % productProvider.featuredProducts.length;
          _featuredProductsController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  Future<void> _loadData() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Products are now pre-fetched instantly when the app loads in main.dart

    // Start listening to user-specific data if logged in
    if (authProvider.isLoggedIn && authProvider.user != null) {
      final userId = authProvider.user!.id;
      _loadedUserId = userId;
      
      Provider.of<NotificationProvider>(context, listen: false)
          .listenToNotifications(userId);
      Provider.of<OrderProvider>(context, listen: false)
          .listenToUserOrders(userId);
      Provider.of<AddressProvider>(context, listen: false)
          .loadAddresses(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.primary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        _buildCategories(context),
                        const SizedBox(height: 32),
                        _buildFeaturedProducts(context),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(16, statusBarHeight + 16, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Furniq',
                      style: AppTextStyles.h3.copyWith(color: AppColors.textLight),
                    ),
                    Text(
                      'Find your perfect furniture',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textLight.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: AppColors.textLight),
                    onPressed: () {
                      Navigator.pushNamed(context, AppRouter.notifications);
                    },
                  ),
                  Consumer<NotificationProvider>(
                    builder: (context, notifProvider, _) {
                      if (notifProvider.unreadCount == 0) return const SizedBox.shrink();
                      return Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${notifProvider.unreadCount}',
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.textLight),
                    onPressed: () {
                      Navigator.pushNamed(context, AppRouter.cart);
                    },
                  ),
                  if (cartProvider.itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${cartProvider.itemCount}',
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.person_outline, color: AppColors.textLight),
                onPressed: () {
                  Navigator.pushNamed(context, AppRouter.profile);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search furniture...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (query) {
              if (query.trim().isNotEmpty) {
                Navigator.pushNamed(context, AppRouter.allProducts, arguments: query.trim());
              }
            },
          ),
        ],
      ),
    );
  }



  Widget _buildCategories(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Shop by Category', style: AppTextStyles.h4),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRouter.allProducts);
                },
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Consumer<ProductProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.categories.isEmpty) {
              return const Center(child: Text('No categories available'));
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: provider.categories.length,
              itemBuilder: (context, index) {
                final category = provider.categories[index];
                final productCount = provider.products.where((prod) => prod.categoryId == category.id).length;
                return _buildCategoryCard(context, category, productCount);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context, Category category, int productCount) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRouter.categoryProducts,
          arguments: {
            'categoryId': category.id,
            'categoryName': category.name,
          },
        );
      },
      child: Card(
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: category.thumbnailImageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.image),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$productCount items',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textLight,
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

  Widget _buildFeaturedProducts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Featured Products', style: AppTextStyles.h4),
        ),
        const SizedBox(height: 12),
        Consumer<ProductProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.featuredProducts.isEmpty) {
              return const Center(child: Text('No featured products'));
            }

            return SizedBox(
              height: 320,
              child: PageView.builder(
                controller: _featuredProductsController,
                padEnds: false,
                itemCount: provider.featuredProducts.length,
                itemBuilder: (context, index) {
                  final product = provider.featuredProducts[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildFeaturedProductCard(context, product),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeaturedProductCard(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRouter.productDetails,
          arguments: product.id,
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.cardBackground,
                ),
                child: CachedNetworkImage(
                  imageUrl: product.mainImageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.image, size: 50),
                ),
              ),
            ),
            // Product Details
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.material,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      Formatters.currency(product.price),
                      style: AppTextStyles.price.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
