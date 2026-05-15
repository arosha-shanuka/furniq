import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'providers/order_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/address_provider.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'services/product_service.dart';
import 'models/product_model.dart';
import 'models/category_model.dart';

import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Set Stripe key synchronously
  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
  
  runApp(const FurniqRoot());
}

class FurniqRoot extends StatefulWidget {
  const FurniqRoot({super.key});

  @override
  State<FurniqRoot> createState() => _FurniqRootState();
}

class _FurniqRootState extends State<FurniqRoot> {
  late Future<FirebaseApp> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).then((app) async {
      Stripe.instance.applySettings();
      
      try {
        final productService = ProductService();
        final futures = await Future.wait([
          productService.getFeaturedProducts(),
          productService.getCategories(),
        ]);
        
        final featured = futures[0] as List<Product>;
        final categories = futures[1] as List<Category>;
        
        // Pre-resolve images to cache them
        for (var p in featured) {
          CachedNetworkImageProvider(p.mainImageUrl).resolve(const ImageConfiguration());
        }
        for (var c in categories) {
          CachedNetworkImageProvider(c.thumbnailImageUrl).resolve(const ImageConfiguration());
        }
      } catch (e) {
        // Ignore errors during pre-fetch
      }
      
      // Ensure splash is visible for at least 1 extra second while images load
      await Future.delayed(const Duration(milliseconds: 1000));
      return app;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return const FurniqApp();
        }
        
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const SplashScreen(),
        );
      },
    );
  }
}

class FurniqApp extends StatelessWidget {
  const FurniqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(
          create: (_) => ProductProvider()
            ..loadCategories()
            ..loadProducts()
            ..loadFeaturedProducts(),
        ),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
      ],
      child: MaterialApp(
        title: 'Furniq',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        onGenerateRoute: AppRouter.generateRoute,
        initialRoute: AppRouter.home,
      ),
    );
  }
}
