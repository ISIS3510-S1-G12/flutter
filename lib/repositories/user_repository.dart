import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:moviles/models/user.dart';

class UserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Crear o actualizar un usuario
  Future<void> saveUser(User user) async {
    await _db
        .collection("Users")
        .doc(user.id)
        .set(user.toFirestore(), SetOptions(merge: true));
  }

  /// Obtener un usuario por su id
  Future<User?> getUser(String userId) async {
    final doc = await _db.collection("Users").doc(userId).get();
    if (!doc.exists) return null;
    return User.fromFirestore(doc.id, doc.data()!);
  }

  /// Actualizar solo preferencias
  Future<void> updateUserPreferences(
      String userId, Map<String, dynamic> preferences) async {
    await _db.collection("Users").doc(userId).update({
      "preferences": preferences,
      "updated_at": FieldValue.serverTimestamp(),
    });
  }

  /// Subir imagen de perfil y devolver la URL
  Future<String> uploadProfilePicture(String userId, String filePath) async {
    final ref = _storage.ref().child("users/$userId/profile.jpg");
    final uploadTask = await ref.putFile(File(filePath));
    return await uploadTask.ref.getDownloadURL();
  }

  /// Agregar restaurante favorito
  Future<void> addFavoriteRestaurant(String userId, String restaurantId) async {
    await _db.collection("Users").doc(userId).update({
      "favorite_restaurants.$restaurantId": FieldValue.serverTimestamp(),
      "updated_at": FieldValue.serverTimestamp(),
    });
  }

  /// Quitar restaurante favorito
  Future<void> removeFavoriteRestaurant(
      String userId, String restaurantId) async {
    await _db.collection("Users").doc(userId).update({
      "favorite_restaurants.$restaurantId": FieldValue.delete(),
      "updated_at": FieldValue.serverTimestamp(),
    });
  }

  /// Actualizar mapa completo de favoritos
  Future<void> updateFavorites(
      String userId, Map<String, Timestamp> favorites) async {
    await _db.collection("Users").doc(userId).update({
      "favorite_restaurants": favorites,
      "updated_at": FieldValue.serverTimestamp(),
    });
  }

  /// Eliminar usuario
  Future<void> deleteUser(String userId) async {
    await _db.collection("Users").doc(userId).delete();
  }
}
