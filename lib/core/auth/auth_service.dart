import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/storage_service.dart';

enum AuthMethod { apple, google, email }

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _lastAuthMethodKey = 'control_bebe.last_auth_method.v1';

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static GoogleSignIn _createGoogleSignIn() => GoogleSignIn();

  /// Login con email y contraseña
  static Future<UserCredential?> signInWithEmail(
    String email,
    String password,
  ) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _rememberAuthMethod(AuthMethod.email);
    return result;
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
    final result = await _auth.signInWithCredential(credential);
    await _rememberAuthMethod(AuthMethod.google);
    return result;
  }

  /// Login con Apple
  static Future<UserCredential?> signInWithApple() async {
    final appleProvider = AppleAuthProvider();
    final result = await _auth.signInWithProvider(appleProvider);
    await _rememberAuthMethod(AuthMethod.apple);
    return result;
  }

  /// Registro con email y contraseña
  static Future<UserCredential?> signUpWithEmail(
    String email,
    String password,
  ) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _rememberAuthMethod(AuthMethod.email);
    return result;
  }

  static Future<AuthMethod?> getLastAuthMethod() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_lastAuthMethodKey);
    for (final method in AuthMethod.values) {
      if (method.name == stored) return method;
    }
    return null;
  }

  static Future<void> _rememberAuthMethod(AuthMethod method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastAuthMethodKey, method.name);
  }

  /// Sesión de invitado (sin correo). Requiere tener "Anónimo" activado en Firebase Auth.
  static Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  /// Cerrar sesión
  static Future<void> signOut() async {
    try {
      await storage.resetLocalSyncState();
    } catch (_) {}
    try {
      await _createGoogleSignIn().signOut();
    } catch (_) {
      // En web sin clientId configurado, GoogleSignIn puede fallar. Ignorar.
    }
    await _auth.signOut();
  }

  /// Elimina la cuenta del usuario y todos sus datos de Firestore.
  /// Si es el único miembro de la familia, elimina también la familia completa.
  static Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await storage.resetLocalSyncState();
    } catch (_) {}

    final uid = user.uid;
    final userDoc = _firestore.collection('users').doc(uid);
    final userSnap = await userDoc.get();
    final familyId = userSnap.data()?['familyId'] as String?;

    if (familyId != null && familyId.isNotEmpty) {
      final familyDoc = _firestore.collection('families').doc(familyId);
      final familySnap = await familyDoc.get();
      final members = List<String>.from(
        (familySnap.data()?['members'] as List?) ?? [],
      );

      if (members.length <= 1) {
        // Único miembro: borrar toda la familia y sus subcolecciones
        for (final sub in [
          'weight_records',
          'height_records',
          'diaper_records',
          'feeding_records',
        ]) {
          final snap = await familyDoc.collection(sub).get();
          for (final doc in snap.docs) {
            await doc.reference.delete();
          }
        }
        await familyDoc.delete();
      } else {
        // Hay más miembros: solo desvincularse
        members.remove(uid);
        await familyDoc.update({'members': members});
      }
    }

    await userDoc.delete();

    try {
      await _createGoogleSignIn().signOut();
    } catch (_) {}

    await user.delete();
  }
}
