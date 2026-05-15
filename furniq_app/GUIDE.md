# Furniq - Step-by-Step Guide

This guide walks you through everything you need to know about the Furniq AR furniture e-commerce application.

---

## 📱 For Users: How to Use the App

### Step 1: Download & Install
1. Download the Furniq APK (or install from Google Play Store)
2. Install on your Android device (Android 10+ required)
3. Grant camera permission for AR features

### Step 2: Create an Account
1. Open the app
2. Tap the **Profile** icon in the top right
3. Tap **Create Account**
4. Enter your name, email, and password
5. Tap **Sign up**

### Step 3: Browse Furniture
1. From the home screen, browse categories:
   - **Sofas** (24 items)
   - **Tables** (18 items)
   - **Beds** (15 items)
   - **Chairs** (32 items)
   - **Decor** (41 items)
2. Use the search bar to find specific items
3. Tap any category to view products

### Step 4: View Product Details
1. Tap on any product
2. View:
   - Product images
   - Price and stock status
   - Material (Fabric, Leather, Wood, etc.)
   - Dimensions
   - Description
   - Material & Care instructions
3. Use **View in AR** to see the furniture in your room (AR feature)
4. Tap **Add to Cart** to purchase

### Step 5: View in AR (Optional)
1. On product details, tap **View in AR**
2. Point your camera at a flat surface (floor or table)
3. Tap to place the furniture
4. Use gestures:
   - **Drag**: Move furniture
   - **Pinch**: Scale size
   - **Rotate**: Turn furniture
5. Tap **Add to Cart** to purchase from AR view

### Step 6: Manage Your Cart
1. Tap the **Cart** icon (top right)
2. Review your items
3. Adjust quantities with **+** and **-** buttons
4. Remove items with the trash icon
5. View total price
6. Tap **Proceed to Checkout**

### Step 7: Checkout & Place Order
1. Fill in **Customer Information**:
   - Full Name
   - Email Address
   - Phone Number
2. Enter **Delivery Address**:
   - Street Address
   - City
   - Postal Code
3. Choose **Payment Method**:
   - **Cash on Delivery** (pay when you receive)
   - **Online Payment** (credit/debit card)
4. Review order summary
5. Tap **Place Order**

### Step 8: Track Your Order
1. After placing order, note your Order Number
2. View order confirmation with:
   - Order details
   - Delivery address
   - Payment method
   - Total amount
3. Check "What's Next?" section for delivery info
4. Tap **Track Order** to see order status
5. Orders screen shows:
   - All your orders
   - Status (pending/processing/delivered)
   - Order dates and amounts

### Step 9: Manage Your Profile
1. Tap **Profile** icon
2. View your account:
   - Name and email
   - Premium Member badge (if applicable)
   - Recent orders
3. Access:
   - **Delivery Addresses**: Manage shipping addresses
   - **Notifications**: View order updates
   - **Settings**: App preferences
   - **Terms & Privacy**: Legal information
4. Tap **Sign Out** to log out

---

## 👨‍💻 For Developers: Setup & Deployment

### Prerequisites Checklist
- [ ] Flutter SDK 3.0.0+ installed
- [ ] Android Studio with Android SDK
- [ ] Firebase account created
- [ ] Git installed
- [ ] Code editor (VS Code or Android Studio)

### Step 1: Install Flutter
```bash
# Windows
# Download from https://flutter.dev/docs/get-started/install/windows
# Extract and add to PATH

# Verify installation
flutter doctor
flutter --version
```

### Step 2: Clone/Open Project
```bash
cd "G:\New folder (2)\furniq"
flutter pub get
```

### Step 3: Firebase Setup

**3.1 Create Firebase Project**
1. Go to https://console.firebase.google.com/
2. Click "Add project"
3. Name: "Furniq"
4. Disable Google Analytics (optional)
5. Click "Create project"

**3.2 Add Android App**
1. In Firebase console, click Android icon
2. Package name: `com.furniq.furniq`
3. App nickname: "Furniq"
4. Download `google-services.json`
5. Place in `android/app/google-services.json`

**3.3 Enable Firebase Services**

Authentication:
1. Go to Authentication → Sign-in method
2. Enable "Email/Password"
3. Save

Firestore:
1. Go to Firestore Database → Create database
2. Start in **test mode**
3. Location: choose closest to Sri Lanka (e.g., asia-south1)
4. Click Enable

Storage:
1. Go to Storage → Get started
2. Start in **test mode**
3. Click Done

**3.4 Configure Flutter App**
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
# Select your Furniq project
# Select platforms: Android, iOS

# This creates lib/firebase_options.dart
```

**3.5 Update Code**

In `lib/main.dart`, uncomment these lines:
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### Step 4: Seed Firebase Data

**Option A: Manual Entry**

In Firestore console, create collections:

`categories` collection:
```json
{
  "name": "Sofas",
  "itemCount": 24,
  "thumbnailImageUrl": "https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=400"
}
```

`products` collection:
```json
{
  "name": "Modern L-Shape Sofa",
  "categoryId": "cat_sofas",
  "price": 1299,
  "material": "Fabric",
  "dimensions": {
    "widthCm": 220,
    "heightCm": 85,
    "depthCm": 95
  },
  "description": "Spacious L-shaped sofa...",
  "materialAndCareText": "Made with high-quality...",
  "stockStatus": "inStock",
  "mainImageUrl": "https://...",
  "arModelUrl": "models/sofa_lshape.glb",
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:00:00Z"
}
```

**Option B: Import Script** (create separately)

### Step 5: Test Run
```bash
# List devices
flutter devices

# Run on connected device
flutter run

# Or run in release mode
flutter run --release
```

### Step 6: Build Release APK
```bash
# Build APK
flutter build apk --release

# APK location:
# build/app/outputs/flutter-apk/app-release.apk

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

### Step 7: Deploy to Play Store

1. **Prepare Assets**:
   - App icon (512x512 PNG)
   - Feature graphic (1024x500)
   - Screenshots (4-8 images)
   - Privacy policy URL

2. **Create Play Console Account**:
   - Go to https://play.google.com/console
   - Pay one-time $25 fee

3. **Create App**:
   - Click "Create app"
   - Enter app details
   - Upload AAB file

4. **Complete Store Listing**:
   - App name: Furniq
   - Short description
   - Full description
   - Category: Shopping
   - Add screenshots

5. **Submit for Review**:
   - Complete all sections
   - Submit for review
   - Wait 1-7 days for approval

---

## 🔧 Troubleshooting

### Issue: "Flutter command not found"
**Solution**: Add Flutter to your system PATH
```bash
# Add to PATH (Windows):
# C:\path\to\flutter\bin
```

### Issue: "google-services.json not found"
**Solution**: 
1. Download from Firebase Console
2. Place in `android/app/` directory
3. Ensure filename is exactly `google-services.json`

### Issue: "Gradle build failed"
**Solution**:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Issue: Images not loading
**Solution**: 
- Check internet connection
- Verify Unsplash URLs are accessible
- Consider uploading images to Firebase Storage

### Issue: Firebase errors
**Solution**:
1. Run `flutterfire configure` again
2. Verify `lib/firebase_options.dart` exists
3. Check Firebase console for enabled services

---

## 📊 App Features Summary

| Feature | Status | Notes |
|---------|--------|-------|
| Authentication | ✅ Ready | Email/password with Firebase |
| Product Catalog | ✅ Ready | 14 products, 5 categories |
| Shopping Cart | ✅ Ready | Full cart management |
| Checkout | ✅ Ready | COD and online payment UI |
| Order Tracking | ✅ Ready | Order history and status |
| Profile Management | ✅ Ready | User profiles with addresses |
| AR Visualization | ⏳ Pending | Requires Unity integration |
| Payment Gateway | ⏳ Pending | Needs API keys |
| Push Notifications | ⏳ Pending | Firebase Cloud Messaging |

---

## 🚀 Production Checklist

### Before Launch
- [ ] Configure Firebase in production mode
- [ ] Add real product images
- [ ] Set up payment gateway (PayHere/Stripe)
- [ ] Create privacy policy page
- [ ] Test on multiple devices
- [ ] Set up error tracking (Sentry/Firebase Crashlytics)
- [ ] Configure app signing key
- [ ] Test all user flows end-to-end
- [ ] Prepare Play Store assets
- [ ] Write help/FAQ section

### After Launch
- [ ] Monitor user feedback
- [ ] Track crash reports
- [ ] Analyze user behavior with Firebase Analytics
- [ ] Respond to reviews
- [ ] Plan feature updates
- [ ] Add Unity AR module
- [ ] Implement push notifications
- [ ] Add product recommendations

---

## 📞 Support & Resources

**Documentation**:
- [README.md](file:///G:/New%20folder%20%282%29/furniq/README.md) - Project overview
- [SETUP.md](file:///G:/New%20folder%20%282%29/furniq/SETUP.md) - Detailed setup guide
- [implementation_plan.md](file:///C:/Users/najir/.gemini/antigravity/brain/04c4326e-9b0a-4370-876b-65ae44fb1e1f/implementation_plan.md) - Technical architecture
- [walkthrough.md](file:///C:/Users/najir/.gemini/antigravity/brain/04c4326e-9b0a-4370-876b-65ae44fb1e1f/walkthrough.md) - Complete feature walkthrough

**External Resources**:
- Flutter Docs: https://flutter.dev/docs
- Firebase Docs: https://firebase.google.com/docs
- Material Design: https://m3.material.io/
- Play Store Guide: https://support.google.com/googleplay/android-developer

---

**Version**: 1.0.0  
**Last Updated**: January 2026  
**Built with**: Flutter 3.0+ | Firebase | Material Design 3
