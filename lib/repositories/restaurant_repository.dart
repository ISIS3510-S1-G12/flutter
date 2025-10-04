import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/restaurant.dart';

class RestaurantRepository {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  /// Obtener todos los restaurantes
  Future<List<Restaurant>> getRestaurants() async {
    final snapshot = await _db.collection("Restaurants").get();
    return snapshot.docs.map((doc) => Restaurant.fromFirestore(doc)).toList();
  }

  /// Guardar restaurante con ID fijo
  Future<void> saveRestaurantWithId(String id, Restaurant restaurant) async {
    await _db.collection("Restaurants").doc(id).set(restaurant.toMap());
  }

  /// Subir imagen y devolver URL
  Future<String> uploadImage(String restaurantId, File imageFile) async {
    final ref = _storage.ref().child("restaurants/$restaurantId.jpg");
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  /// Obtener un restaurante por ID
  Future<Restaurant?> getRestaurantById(String id) async {
    final doc = await _db.collection("Restaurants").doc(id).get();
    if (!doc.exists) return null;
    return Restaurant.fromFirestore(doc);
  }

  /// Obtener restaurantes favoritos a partir de un mapa {restaurantId: timestamp}
    Future<List<Restaurant>> getFavoriteRestaurants(
          Map<String, Timestamp> favoritesMap) async {
        if (favoritesMap.isEmpty) return [];

        final ids = favoritesMap.keys.toList();
        final snapshot = await _db
            .collection("Restaurants")
            .where(FieldPath.documentId, whereIn: ids)
            .get();

        return snapshot.docs.map((doc) => Restaurant.fromFirestore(doc)).toList();
      }
}
