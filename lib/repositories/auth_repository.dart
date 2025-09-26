import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Registro básico
  Future<String> register({
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

      final data = {
        "email": email.trim(),
        "password": password,
        "ownerUid": uid, 
        "name": name,
        "role": who,
        "created_at": FieldValue.serverTimestamp(),
      };

      if (who == "user") {
        await _db.collection("Users").doc(uid).set(data);
      } else if (who == "restaurant") {
        await _db.collection("Restaurants").doc(uid).set(data);
      } else {
        throw Exception("Invalid user type");
      }

      return uid;
    } catch (e) {
      throw Exception("Register failed: $e");
    }
  }

  // Obtener rol
  Future<String?> getUserRole(String uid) async {
    final userDoc = await _db.collection("Users").doc(uid).get();
    if (userDoc.exists) return userDoc.data()?["role"];

    final restaurantDoc = await _db.collection("Restaurants").doc(uid).get();
    if (restaurantDoc.exists) return restaurantDoc.data()?["role"];

    return null;
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

    if (role?.trim().toLowerCase() == expectedRole.toLowerCase()) {
      return uid; // devuelve UID
    } else {
      await _auth.signOut();
      throw Exception("Acceso denegado: rol inválido");
    }
  }

  Future<void> logout() async => await _auth.signOut();
}
