import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'timetable_storage.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  static Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (_) {
      return const Stream.empty();
    }
  }

  // --- Sign In with Google ---
  static Future<UserCredential?> signInWithGoogle({required TimetableStorage storage}) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled sign-in prompt
        return null;
      }

      try {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);
        final user = userCredential.user;

        if (user != null) {
          await storage.saveUserProfile(
            uid: user.uid,
            name: user.displayName ?? googleUser.displayName ?? 'Student',
            email: user.email ?? googleUser.email,
            photoUrl: user.photoURL ?? googleUser.photoUrl,
          );
        }

        return userCredential;
      } catch (credentialError) {
        debugPrint('Firebase Credential Exchange Note (using Google profile directly): $credentialError');
        // If Firebase Auth rejects credentials due to missing SHA-1 or unconfigured OAuth in console,
        // we still have verified GoogleSignIn identity from googleUser!
        final safeUid = 'g_${googleUser.id.isNotEmpty ? googleUser.id : googleUser.email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
        await storage.saveUserProfile(
          uid: safeUid,
          name: googleUser.displayName ?? 'Student',
          email: googleUser.email,
          photoUrl: googleUser.photoUrl,
        );
        return null;
      }
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  // --- Direct College Email Sign In / Fallback ---
  static Future<void> signInWithEmailDirect({
    required String email,
    required String name,
    required TimetableStorage storage,
  }) async {
    try {
      // In development/offline mode or before SHA-1 is added, allow direct student sign-in
      final uid = 'user_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
      await storage.saveUserProfile(
        uid: uid,
        name: name.trim().isNotEmpty ? name.trim() : email.split('@').first,
        email: email.trim(),
      );
    } catch (e) {
      debugPrint('Direct Sign-In Error: $e');
      rethrow;
    }
  }

  // --- Sign Out ---
  static Future<void> signOut({required TimetableStorage storage}) async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google Sign-Out Note: $e');
    }

    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Firebase Sign-Out Note: $e');
    }

    await storage.clearUserProfile();
  }
}
