import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Registrar un usuario
  Future<void> register({
    required String who,
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      if (who == "user") {
      
      // 1. Crear el usuario en Authentication
      final UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = cred.user!.uid;

      // 2. Guardar sus datos en Firestore
      await _db.collection("Users").doc(uid).set({
        "email": email.trim(),
        "favorite_restaurants": null,
        "name": name,
        "preferences": null,
        "profile_picture": null,
        "password": password,

      });
      } else if (who == "restaurant") {
        // 1. Crear el usuario en Authentication
        final UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        final uid = cred.user!.uid;
  
        // 2. Guardar sus datos en Firestore
        await _db.collection("Restaurants").doc(uid).set({
          "address": null,
          "busiest_hours": null,
          "closing_time": null,
          "email": email.trim(),
          "location": null,
          "name": name,
          "opening_time": null,
          "password": password,
          "restaurant_image": null,
          "restaurant_type": null,
        });
      } else {
        throw Exception("Invalid user type");
      }
    } catch (e) {
      throw Exception("Register failed: $e");
    }
  }

  // Login
  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}
