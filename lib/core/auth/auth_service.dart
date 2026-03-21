import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/auth_config.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static GoogleSignIn _createGoogleSignIn() {
    if (kIsWeb && AuthConfig.googleWebClientId != null) {
      return GoogleSignIn(clientId: AuthConfig.googleWebClientId);
    }
    return GoogleSignIn();
  }

  /// Login con email y contraseña
  static Future<UserCredential?> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Envía correo de restablecimiento de contraseña (Firebase Auth).
  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Login con Google
  static Future<UserCredential?> signInWithGoogle() async {
    final googleSignIn = _createGoogleSignIn();
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return await _auth.signInWithCredential(credential);
  }

  /// Login con Apple
  static Future<UserCredential?> signInWithApple() async {
    final appleProvider = AppleAuthProvider();
    return await _auth.signInWithProvider(appleProvider);
  }

  /// Registro con email y contraseña
  static Future<UserCredential?> signUpWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  /// Sesión de invitado (sin correo). Requiere tener "Anónimo" activado en Firebase Auth.
  static Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  /// Cerrar sesión
  static Future<void> signOut() async {
    try {
      await _createGoogleSignIn().signOut();
    } catch (_) {
      // En web sin clientId configurado, GoogleSignIn puede fallar. Ignorar.
    }
    await _auth.signOut();
  }
}
