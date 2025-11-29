import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:moviles/models/user.dart';

class UserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> saveUser(User user) async {
    await _db
        .collection("Users")
        .doc(user.id)
        .set(user.toFirestore(), SetOptions(merge: true));
  }

  Future<User?> getUser(String userId) async {
    final doc = await _db.collection("Users").doc(userId).get();
    if (!doc.exists) return null;
    return User.fromFirestore(doc.id, doc.data()!);
  }

  Future<void> updateUserPreferences(
      String userId, Map<String, dynamic> preferences) async {
    await _db.collection("Users").doc(userId).update({
      "preferences": preferences,
      "updated_at": FieldValue.serverTimestamp(),
    });
  }

  // --- Nuevo: Subir imagen a Firebase Storage y retornar URL ---
  Future<String> uploadProfilePictureFile(String userId, File image) async {
    final ref = _storage.ref().child("users/$userId/profile.jpg");
    final uploadTask = await ref.putFile(image);
    return await uploadTask.ref.getDownloadURL();
  }

  // --- Nuevo: Actualizar usuario completo incluyendo foto ---
  Future<void> updateUser(
      {required User user, File? profileImage}) async {
    String? imageUrl;

    if (profileImage != null) {
      imageUrl = await uploadProfilePictureFile(user.id, profileImage);
    }

    final data = user.toFirestore();

    if (imageUrl != null) {
      data['profile_picture'] = imageUrl;
    }

    await _db.collection("Users").doc(user.id).update(data);
  }

  // Favoritos
  Future<void> addFavoriteRestaurant(String userId, String restaurantId) async {
    await _db.collection("Users").doc(userId).update({
      "favorite_restaurants.$restaurantId": FieldValue.serverTimestamp(),
      "updated_at": FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFavoriteRestaurant(String userId, String restaurantId) async {
    await _db.collection("Users").doc(userId).update({
      "favorite_restaurants.$restaurantId": FieldValue.delete(),
      "updated_at": FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateFavorites(String userId, Map<String, Timestamp> favorites) async {
    await _db.collection("Users").doc(userId).update({
      "favorite_restaurants": favorites,
      "updated_at": FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteUser(String userId) async {
    await _db.collection("Users").doc(userId).delete();
  }

  Future<String> uploadProfilePicture(String userId, String filePath) async { 
    final ref = _storage.ref().child("users/$userId/profile.jpg"); 
    final uploadTask = await ref.putFile(File(filePath)); 
  return await uploadTask.ref.getDownloadURL(); }
}
