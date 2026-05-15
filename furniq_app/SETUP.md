# Furniq - Setup Guide

## Prerequisites

Before you begin, ensure you have the following installed:
- **Flutter SDK** (3.0.0 or higher)
- **Android Studio** with Android SDK (or Xcode for iOS)
- **Git**
- **VS Code** or **Android Studio** (for development)
- **Node.js** (for deploying Firebase Cloud Functions)
- **Unity Hub & Unity Editor** (version `2022.2.1` or compatible, for AR features)

## Step 1: Install Flutter

1. Download Flutter SDK from [flutter.dev](https://flutter.dev/docs/get-started/install)
2. Extract and add Flutter to your PATH
3. Run `flutter doctor` to verify installation
4. Install any missing dependencies

## Step 2: Set Up the Project

1. Navigate to the project directory:
   ```bash
   cd furniq
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

## Step 3: Configure Firebase

### 3.1 Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" and name it **Furniq**.
3. Follow the setup wizard to create the project.

### 3.2 Enable Firebase Services

In the Firebase console:
1. **Authentication**: Go to Authentication → Sign-in method and enable "Email/Password".
2. **Firestore Database**: Go to Firestore Database → Create database. Start in test mode (you will apply security rules later).
3. **Firebase Storage**: Go to Storage → Get started. Start in test mode.
4. **Cloud Functions**: Upgrade your Firebase project to the Blaze (pay-as-you-go) plan to deploy Node.js functions.

### 3.3 Update Firebase Configuration

1. Run FlutterFire CLI to generate configuration:
   ```bash
   flutter pub global activate flutterfire_cli
   flutterfire configure
   ```
2. Follow the prompts to select your Android and iOS applications. This will create `lib/firebase_options.dart`.

## Step 4: Configure Stripe & Cloud Functions

Furniq uses Stripe for secure payment processing and Firebase Cloud Functions for order management and notifications.

### 4.1 Obtain Stripe Keys
1. Create a [Stripe account](https://dashboard.stripe.com/).
2. Obtain your **Publishable key** and **Secret key** from the Stripe Dashboard (Developers → API keys).

### 4.2 Deploy Firebase Cloud Functions
1. Navigate to the functions directory:
   ```bash
   cd functions
   npm install
   ```
2. Set your Stripe Secret Key as a Firebase Secret for Cloud Functions:
   ```bash
   firebase functions:secrets:set STRIPE_SECRET_KEY
   # Paste your sk_test_... key when prompted
   ```
3. Deploy the Cloud Functions:
   ```bash
   firebase deploy --only functions
   ```

### 4.3 Configure Flutter Stripe
Add your Stripe **Publishable key** in the `lib/main.dart` or your environment variables:
```dart
Stripe.publishableKey = 'pk_test_...';
```

## Step 5: AR Unity Setup

The AR functionality relies on the `flutter_unity_widget`.
1. Make sure you have the Unity project exported.
2. The Unity export should be located in the `android/unityLibrary` and `ios/UnityLibrary` directories.
3. If you make changes to the AR scene in Unity, you must re-export the project targeting Android and/or iOS into these folders.
4. The `flutter_unity_widget` handles the communication between Flutter and the embedded Unity view.

## Step 6: Configure Android

1. The project requires `FlutterFragmentActivity` for Stripe to work correctly. Ensure `android/app/src/main/kotlin/.../MainActivity.kt` extends `FlutterFragmentActivity`. (This is already implemented in the current codebase).
2. Ensure your `android/app/build.gradle` has a `minSdkVersion` of at least `21`.

## Step 7: Run the App

1. Connect an Android/iOS device or start an emulator. Note that Unity AR features will not work on standard simulators/emulators—you must use a physical device.
2. Check connected devices:
   ```bash
   flutter devices
   ```
3. Run the app:
   ```bash
   flutter run
   ```

## Troubleshooting

### Common Issues

**Issue**: `google-services.json not found`
- **Solution**: Make sure you ran `flutterfire configure` to generate the necessary platform configuration files.

**Issue**: Stripe Payment Sheet crashes on Android
- **Solution**: Verify your `MainActivity` extends `FlutterFragmentActivity`. Check your app theme in `styles.xml` matches Stripe requirements (should inherit from a `Theme.AppCompat` variant).

**Issue**: Cloud Functions fail to deploy
- **Solution**: Ensure your Firebase project is on the Blaze plan. Make sure you're using Node.js version 18 or 20.

**Issue**: Unity AR View is blank or crashes
- **Solution**: Re-export the Unity project. Ensure the NDK version matches the Unity requirements. Test on a physical device.

## Support

For questions or issues:
- Check Flutter documentation: https://flutter.dev/docs
- Firebase documentation: https://firebase.google.com/docs
- Stripe documentation: https://stripe.com/docs
- flutter_unity_widget: https://pub.dev/packages/flutter_unity_widget

---

Built with Flutter 🚀 | Furniq AR Furniture Shopping App
