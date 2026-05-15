import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'This admin panel is designed for web only.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDI8ildYNkbRgW3pmSY-FNwtHreXNxDdOc',
    appId: '1:774210778512:web:efa5095e76a82f7b282f15',
    messagingSenderId: '774210778512',
    projectId: 'furniq-78b5a',
    authDomain: 'furniq-78b5a.firebaseapp.com',
    storageBucket: 'furniq-78b5a.firebasestorage.app',
    measurementId: 'G-PCSTC85HVJ',
  );
}
