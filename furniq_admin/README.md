# Furniq Admin Panel

![Furniq Admin](https://img.shields.io/badge/Flutter-Web-02569B?logo=flutter&logoColor=white) ![Firebase](https://img.shields.io/badge/Firebase-Integration-FFCA28?logo=firebase&logoColor=white)

Furniq Admin is a comprehensive Flutter Web application designed to serve as the central command center for the Furniq e-commerce platform. It provides a secure, role-based dashboard for administrators to manage products, order fulfillment, category organization, and asset hosting.

## 🚀 Features

- **Product Management:** Complete CRUD operations for products. Features advanced input handling for prices (LKR) and robust file uploading for AR models (`.glb`) and images.
- **Order Fulfillment:** Real-time tracking and management of customer orders.
- **Category Organization:** Hierarchical structuring of inventory via a dedicated category management interface.
- **Asset Storage:** Direct integration with Firebase Storage for seamless 3D model and image hosting.
- **Responsive Dashboard:** Built with `admin_shell` for a responsive, persistent navigation rail layout.
- **Secure Authentication:** Firebase Auth integration ensuring only authorized personnel can access the dashboard.

## 🏗 Architecture & Project Structure

This project follows a clean architecture pattern utilizing **Provider** for state management and **Firebase** as the Backend-as-a-Service (BaaS). The codebase is strictly separated into Models, Services, Providers, and Screens.

```text
lib/
├── main.dart                  # Application entry point and Provider scope initialization
├── firebase_options.dart      # Auto-generated Firebase configuration
├── sync_categories.dart       # Utility script for syncing/seeding initial category data
│
├── models/                    # Data Structures
│   ├── category_model.dart    # Schema for product categories
│   ├── order_model.dart       # Schema for customer orders and line items
│   └── product_model.dart     # Schema for products, including AR asset URLs and hex colors
│
├── services/                  # Firebase Interaction Layer
│   ├── auth_service.dart      # Handles Firebase Authentication (Login/Logout)
│   ├── category_service.dart  # Firestore CRUD operations for Categories
│   ├── order_service.dart     # Firestore CRUD operations for Orders
│   ├── product_service.dart   # Firestore CRUD operations for Products
│   └── storage_service.dart   # Firebase Storage operations for image/GLB uploads
│
├── providers/                 # State Management & Business Logic
│   ├── auth_provider.dart     # Manages user session state and authentication logic
│   ├── category_provider.dart # Manages category list state and UI updates
│   ├── order_provider.dart    # Manages order fetching and status updates
│   └── product_provider.dart  # Manages product inventory state
│
└── screens/                   # User Interface
    ├── admin_shell.dart       # The main responsive layout wrapper (Sidebar/Navigation)
    ├── dashboard_screen.dart  # High-level metrics and overview dashboard
    ├── login_screen.dart      # Authentication UI
    ├── splash_screen.dart     # Initial loading and auth-check screen
    ├── categories/
    │   ├── category_form_screen.dart # UI for creating/editing categories
    │   └── category_list_screen.dart # Data table view of all categories
    ├── orders/
    │   ├── order_detail_screen.dart  # Deep-dive view of a specific order
    │   └── order_list_screen.dart    # Data table view of all orders
    └── products/
        ├── product_form_screen.dart  # Complex form for product creation, including file pickers
        └── product_list_screen.dart  # Data table view of inventory
```

## 🛠 Tech Stack

- **Framework:** [Flutter](https://flutter.dev/) (Web Target)
- **State Management:** `provider`
- **Backend:** Firebase Core, Cloud Firestore, Firebase Auth, Firebase Storage
- **UI Libraries:** `data_table_2` (Advanced grids), `file_picker` (Asset uploads), `flutter_colorpicker` (Hex code management)
- **Utilities:** `intl` (Currency/Date formatting), `uuid` (Unique ID generation)

## 🏁 Getting Started

### Prerequisites

- Flutter SDK `^3.0.0`
- A configured Firebase project with Web support, Firestore, Authentication (Email/Password), and Storage enabled.

### Local Development Setup

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd furniq_admin
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   Ensure `lib/firebase_options.dart` is correctly configured for your Firebase environment. If you need to generate a new one, use the FlutterFire CLI:
   ```bash
   flutterfire configure
   ```

4. **Run the Application:**
   Launch the application in Chrome:
   ```bash
   flutter run -d chrome
   ```

## 📦 Building for Production

To compile the application for deployment (e.g., Firebase Hosting):

```bash
flutter build web --release
```

This will generate an optimized, minified web build in the `build/web` directory.

### Deploying to Firebase Hosting

If you have the Firebase CLI installed and initialized:

```bash
firebase deploy --only hosting
```

## 🤝 Contributing

When contributing to this project, please ensure:
- State management strictly utilizes the existing `Provider` architecture.
- New database operations are placed within the `services/` directory, while UI state is handled in `providers/`.
- All prices are formatted in **LKR** consistently across the platform.

## 📄 License

This project is proprietary and confidential to Furniq.
