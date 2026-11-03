
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static bool _initialized = false;

  Future<UserCredential> signInWithGoogle() async {
    // Web: use Firebase's Google popup.
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      provider.addScope('email');

      return await _auth.signInWithPopup(provider);
    }

    // Android: use Google Sign-In.
    if (!_initialized) {
      await GoogleSignIn.instance.initialize();
      _initialized = true;
    }

    final GoogleSignInAccount account =
        await GoogleSignIn.instance.authenticate();

    final GoogleSignInAuthentication authentication =
        account.authentication;

    final String? idToken = authentication.idToken;

    if (idToken == null) {
      throw Exception('Google did not provide an ID token.');
    }

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _auth.signOut();

    if (!kIsWeb && _initialized) {
      await GoogleSignIn.instance.signOut();
    }
  }
}
