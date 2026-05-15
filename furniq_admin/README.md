# Furniq Admin Panel

Furniq Admin is a Flutter-based web dashboard designed for managing the Furniq e-commerce platform. It provides a secure, streamlined interface for administrators to manage products, categories, assets, and other operational data.

## Features

- **Product Management:** Create, read, update, and delete products. Support for AR model files (.glb) and image assets.
- **Category Management:** Organize products into categories for easier navigation.
- **Asset Management:** Upload and manage 3D models and images directly to Firebase Storage.
- **Color & Pricing Management:** Robust inputs for hex colors and handling prices in LKR.
- **Firebase Integration:** Real-time data sync with Cloud Firestore and Firebase Auth for secure access.

## Tech Stack

- **Framework:** Flutter (Web)
- **State Management:** Provider
- **Backend Services:** Firebase (Auth, Firestore, Storage)
- **UI Components:** `data_table_2` for advanced data grids, `file_picker` for asset uploads.

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- A Firebase project configured for Web with Firestore, Auth, and Storage enabled.

### Installation

1. Clone the repository and navigate to the project directory:
   ```bash
   cd furniq_admin
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase:
   Ensure you have your `firebase_options.dart` configured for your Firebase project in the `lib/` directory.

4. Run the application (targeting Chrome/Web):
   ```bash
   flutter run -d chrome
   ```

## Building for Production

To build the web version for production deployment:

```bash
flutter build web
```

This will generate a `build/web` directory containing the static files which can be hosted on Firebase Hosting or any other static web host.
