# Furniq

An AR-enabled furniture e-commerce mobile application for Sri Lanka, built with Flutter.

## Features

- 🏠 Browse furniture by categories (Sofas, Tables, Beds, Chairs, Decor)
- 🔍 Product search and filtering
- 📱 Detailed product information with images and specifications
- 📐 AR visualization (Integrated via Unity and `flutter_unity_widget`)
- 🛒 Shopping cart with quantity management
- 💳 Checkout with Cash on Delivery and Secure Online Payment (Stripe Integration)
- 📦 Order tracking and history
- 👤 User authentication and profiles
- 📍 Delivery address management
- 🔔 Real-time Notifications for Order Status Updates

## Technology Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Authentication, Firestore, Storage, Cloud Functions)
- **State Management**: Provider
- **Payment Gateway**: Stripe SDK
- **AR**: Unity + `flutter_unity_widget`
- **UI**: Material Design 3

## Getting Started

### Prerequisites

- Flutter SDK 3.0.0+
- Android Studio / Xcode
- Firebase account
- Stripe account (for payments)
- Unity (for modifying AR features)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   cd furniq
   flutter pub get
   ```

3. Configure Firebase and Stripe (see SETUP.md for detailed instructions)

4. Run the app:
   ```bash
   flutter run
   ```

For detailed setup instructions, see [SETUP.md](SETUP.md).

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── data/                     # Sample data
├── models/                   # Data models
├── services/                 # Business logic and Firebase services
├── providers/                # State management
├── screens/                  # UI screens
│   ├── auth/                # Authentication screens
│   ├── home/                # Home screen
│   ├── products/            # Product-related screens
│   ├── cart/                # Shopping cart
│   ├── checkout/            # Checkout flow with Stripe
│   ├── orders/              # Order history
│   ├── profile/             # User profile
│   ├── address/             # Address management
│   ├── ar/                  # AR viewer (Unity)
│   ├── notifications/       # Notifications
│   ├── settings/            # Settings
│   └── info/                # Terms & Privacy
├── widgets/                 # Reusable widgets
├── theme/                   # App theming
├── routes/                  # Navigation
└── utils/                   # Utilities
```

## Features in Detail

### Authentication
- Email/password authentication via Firebase Auth
- User profiles synced with Firestore
- Persistent sessions

### Product Catalog
- Scalable catalog using Firestore collections
- High-quality product images from Firebase Storage
- Detailed specifications

### Shopping Experience
- Add to cart
- Quantity management
- Price calculations with tax
- Localized pricing in LKR

### Checkout & Payments
- Customer information form
- Delivery address management
- Secure Payment method selection (COD / Stripe Online Payment)
- Order summary

### Order Management & Notifications
- Order confirmation and history
- Real-time status tracking
- Push notifications via Firebase Cloud Messaging & Cloud Functions

### AR Integration
- Fully integrated 3D furniture models.
- Augmented Reality viewer using Unity, enabling users to visualize furniture in their space.

## Development Notes

### Current Implementation Status
- ✅ Complete Flutter UI
- ✅ State management with Provider
- ✅ Firebase Backend Integration (Auth, Firestore, Storage, Functions)
- ✅ Stripe Payment Gateway Integration
- ✅ Unity AR Integration (`flutter_unity_widget`)
- ✅ Navigation and routing

### Next Steps
1. Add more robust test coverage (Widget/Unit tests)
2. Deploy the Admin Web Portal for store management
3. Test physical device performance for Unity AR
4. Prepare Android/iOS release builds for App Store & Google Play

## Contributing

This is a complete demonstration project. For production deployment:
- Enhance Firebase security rules
- Validate inputs extensively
- Set up automated CI/CD pipelines
- Configure proper App Signing

## Support

For questions or issues, refer to:
- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Stripe Documentation](https://stripe.com/docs)

---

Built with ❤️ using Flutter
