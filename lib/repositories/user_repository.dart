// lib/repositories/user_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Obtener datos del usuario por ID
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _db.collection("Users").doc(uid).get();
    return doc.data();
  }

  // Actualizar perfil (ejemplo: nombre, foto, preferencias, etc.)
  Future<void> updateUserProfile(
    String uid, {
    String? name,
    String? profilePicture,
    Map<String, dynamic>? preferences,
    List<String>? favoriteRestaurants,
  }) async {
    final data = <String, dynamic>{};

    if (name != null) data['name'] = name;
    if (profilePicture != null) data['profile_picture'] = profilePicture;
    if (preferences != null) data['preferences'] = preferences;
    if (favoriteRestaurants != null) {
      data['favorite_restaurants'] = favoriteRestaurants;
    }

    await _db.collection("Users").doc(uid).update(data);
  }
}
