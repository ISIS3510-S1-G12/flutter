import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Registrar un usuario o restaurante
  Future<void> register({
    required String who, // "user" o "restaurant"
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = cred.user!.uid;

      if (who == "user") {
        await _db.collection("Users").doc(uid).set({
          "email": email.trim(),
          "name": name,
          "password": password,
          "role": "user",
        });
      } else if (who == "restaurant") {
        await _db.collection("Restaurants").doc(uid).set({
          "email": email.trim(),
          "name": name,
          "password": password,
          "role": "restaurant",
        });
      } else {
        throw Exception("Invalid user type");
      }
    } catch (e) {
      throw Exception("Register failed: $e");
    }
  }

  // Obtener el rol según UID
  Future<String?> getUserRole(String uid) async {
    try {
      final userDoc = await _db.collection("Users").doc(uid).get();
      if (userDoc.exists) return userDoc.data()?["role"];

      final restaurantDoc = await _db.collection("Restaurants").doc(uid).get();
      if (restaurantDoc.exists) return restaurantDoc.data()?["role"];

      return null;
    } catch (e) {
      throw Exception("Error al obtener rol: $e");
    }
  }

  // Login con verificación de rol
  Future<String?> login({
    required String email,
    required String password,
    required String expectedRole, // "user" o "restaurant"
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = cred.user!.uid;
    final role = await getUserRole(uid);

    // Debugging prints para confirmar qué está llegando
    print("🔥 Rol Firestore: '$role'");
    print("🎯 Rol esperado: '$expectedRole'");

    // Validación segura (quita espacios y convierte a minúsculas)
    if (role?.trim().toLowerCase() == expectedRole.toLowerCase()) {
      return role; // ✅ autorizado
    } else {
      // ❌ rol incorrecto → logout inmediato
      await _auth.signOut();
      throw Exception("Acceso denegado: rol inválido");
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
