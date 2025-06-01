import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  // Get the current user
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  // Google sign-in
  Future<User?> signInWithGoogle() async {
    try {
      // Attempt to sign in silently (if the user has signed in previously)
      GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      
      // If no user is signed in silently, perform interactive sign-in
      googleUser ??= await _googleSignIn.signIn();

      if (googleUser == null) {
        log("Google Sign-In was canceled by the user.");
        return null;
      }

      // Obtain authentication details from the Google account
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a credential using the Google sign-in token
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with the credential
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);

      // Log the user's email
      log("User signed in: ${userCredential.user?.email}");

      // Return the signed-in user
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      log("FirebaseAuthException: ${e.code} - ${e.message}");
      return null;
    } on Exception catch (e) {
      log("Exception: $e");
      return null;
    }
  }
}