import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  // User stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Sign in with Email and Password
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user != null) {
        await _saveUserToFirestore(result.user!);
      }
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Register with Email and Password
  Future<User?> registerWithEmailPassword(String email, String password, String name) async {
    try {
      print("Attempting to create user with email: $email");
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? user = result.user;
      if (user != null) {
        print("User created successfully: ${user.uid}");
        try {
          await user.updateDisplayName(name);
          await user.reload();
          // Important: after reload, we should re-fetch if we need strict property consistency, 
          // but for firestore saving, the current user object is fine or we can use the updated one.
          // Let's pass the user with the new name.
           await _saveUserToFirestore(user, name: name);
        } catch (e) {
          print("Failed to update display name or save to firestore: $e");
        }
      } else {
        print("User creation failed: Result user is null");
        throw FirebaseAuthException(
          code: 'user-null',
          message: 'User creation returned null, possibly due to a service error.',
        );
      }
      return user;
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException in register: ${e.code} - ${e.message}");
      throw _handleAuthException(e);
    } catch (e) {
      print("General Exception in register: $e");
      throw Exception(e.toString());
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;
      
      if (user != null) {
        await _saveUserToFirestore(user);
      }
      
      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      print('Google Sign In Error: $e');
      return null; 
    }
  }

  // Save User to Firestore
  Future<void> _saveUserToFirestore(User user, {String? name}) async {
    try {
      final userDocRef = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDocRef.get();

      if (docSnapshot.exists) {
        // Update existing user (just last login)
        await userDocRef.update({
          'last_login': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new user entry
        await userDocRef.set({
          'uid': user.uid,
          'email': user.email,
          'display_name': name ?? user.displayName, // Use provided name or existing
          'photo_url': user.photoURL,
          'created_at': FieldValue.serverTimestamp(),
          'last_login': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("Error saving user to Firestore: $e");
      // Decide if we want to block login if saving fails. 
      // Usually better to log and allow, or rethrow if critical.
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Error Handler
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password is too weak.';
      default:
        return e.message ?? 'An undefined error occurred.';
    }
  }
}
