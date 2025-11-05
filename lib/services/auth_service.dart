import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Crear cuenta
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      print('Error en registro: ${e.code} - ${e.message}');
      rethrow; // Mantenemos el rethrow para manejar en el UI
    } catch (e) {
      print('Error inesperado en registro: $e');
      rethrow;
    }
  }

  // Iniciar sesión
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      print('Error en login: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Error inesperado en login: $e');
      rethrow;
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error en logout: $e');
      rethrow;
    }
  }

  // Recuperar contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print('Error en recuperación: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Error inesperado en recuperación: $e');
      rethrow;
    }
  }

  // Usuario actual
  User? get currentUser => _auth.currentUser;

  // Stream de cambios de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}