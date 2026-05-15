import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get current Firebase user
  firebase_auth.User? get firebaseUser => _firebaseAuth.currentUser;
  
  // Check if user is logged in
  bool get isLoggedIn => _firebaseAuth.currentUser != null;
  
  // Get current user ID
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  // Auth state changes stream
  Stream<firebase_auth.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Sign up with email and password
  Future<User?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Create user with Firebase Auth
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        throw Exception('Failed to create user');
      }

      // Update display name
      await credential.user!.updateDisplayName(name);
      
      // Create user document in Firestore
      final user = User(
        id: credential.user!.uid,
        name: name,
        email: email,
        premiumFlag: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Try to save to Firestore, but don't fail sign up if it fails
      try {
        await _firestore.collection('users').doc(user.id).set({
          'id': user.id,
          'name': user.name,
          'email': user.email,
          'premiumFlag': user.premiumFlag,
          'defaultAddressId': user.defaultAddressId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (firestoreError) {
        // Log but don't fail - user is already created in Firebase Auth
        debugPrint('Firestore save error (non-critical): $firestoreError');
      }
      
      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Sign up error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Sign up error: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        throw Exception('Failed to sign in');
      }

      // Get user data from Firestore
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .get();
        
        if (userDoc.exists && userDoc.data() != null) {
          return User.fromMap(userDoc.data()!, credential.user!.uid);
        }
      } catch (firestoreError) {
        debugPrint('Firestore read error (non-critical): $firestoreError');
      }
      
      // Return basic user if Firestore read fails or document doesn't exist
      return User(
        id: credential.user!.uid,
        name: credential.user!.displayName ?? 'User',
        email: email,
        premiumFlag: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Sign in error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  // Get current user data from Firestore
  Future<User?> getCurrentUserData() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) return null;
      
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();
        
        if (userDoc.exists && userDoc.data() != null) {
          return User.fromMap(userDoc.data()!, firebaseUser.uid);
        }
      } catch (firestoreError) {
        debugPrint('Firestore read error: $firestoreError');
      }
      
      // Return basic user from Firebase Auth if Firestore fails
      return User(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'User',
        email: firebaseUser.email ?? '',
        premiumFlag: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Get user data error: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateProfile(User user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .update({
            'name': user.name,
            'email': user.email,
            'premiumFlag': user.premiumFlag,
            'defaultAddressId': user.defaultAddressId,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      // Update display name in Firebase Auth
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.updateDisplayName(user.name);
      }
    } catch (e) {
      debugPrint('Update profile error: $e');
      rethrow;
    }
  }

  // Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Send Email Verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Reload user to get latest emailVerified status
  Future<bool> reloadAndCheckEmailVerified() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        // Force refresh the auth token first
        await user.getIdToken(true);
        // Then reload the user profile from the server
        await user.reload();
        
        // Return directly from the user object which gets updated in place
        return user.emailVerified;
      }
      return false;
    } catch (e) {
      debugPrint('Reload user error: $e');
      rethrow;
    }
  }

  // Handle Firebase Auth exceptions
  Exception _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return Exception('The password provided is too weak.');
      case 'email-already-in-use':
        return Exception('An account already exists for that email.');
      case 'invalid-email':
        return Exception('The email address is not valid.');
      case 'user-not-found':
        return Exception('No user found for that email.');
      case 'wrong-password':
        return Exception('Wrong password provided.');
      case 'user-disabled':
        return Exception('This user account has been disabled.');
      case 'too-many-requests':
        return Exception('Too many attempts. Please try again later.');
      case 'invalid-credential':
        return Exception('Invalid email or password.');
      default:
        return Exception(e.message ?? 'An authentication error occurred.');
    }
  }
}
