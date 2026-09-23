import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Register a new user with Email & Password and store profile in Firestore
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('User creation failed: No user returned from Firebase');
      }

      await user.updateDisplayName(name.trim());

      final userModel = UserModel(
        uid: user.uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone?.trim(),
        role: role.toUpperCase(),
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(userModel.toFirestore());
      return userModel;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during registration: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Error during registration: $e');
      rethrow;
    }
  }

  /// Sign in with Email & Password and fetch user profile from Firestore
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Sign in failed: No user returned from Firebase');
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        // Create fallback profile if missing
        final fallback = UserModel(
          uid: user.uid,
          name: user.displayName ?? 'User',
          email: user.email ?? email,
          role: 'CUSTOMER',
          createdAt: DateTime.now(),
        );
        await _firestore.collection('users').doc(user.uid).set(fallback.toFirestore());
        return fallback;
      }

      return UserModel.fromFirestore(doc);
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during sign in: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Error during sign in: $e');
      rethrow;
    }
  }

  /// Fetch user profile from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user profile for $uid: $e');
      return null;
    }
  }

  /// Stream of user profile changes
  Stream<UserModel?> streamUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Update user profile
  Future<void> updateProfile(UserModel updatedUser) async {
    try {
      await _firestore
          .collection('users')
          .doc(updatedUser.uid)
          .update(updatedUser.toFirestore());
      if (currentUser != null && updatedUser.name.isNotEmpty) {
        await currentUser!.updateDisplayName(updatedUser.name);
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  /// Real Firebase Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'network-request-failed':
        return 'Network connection failed. Please check your internet connection.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
