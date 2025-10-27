import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/restaurant.dart';

class RestaurantRepository {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  /// Obtener todos los restaurantes (una sola vez)
  Future<List<Restaurant>> getRestaurants() async {
    final snapshot = await _db.collection("Restaurants").get();
    return snapshot.docs.map((doc) => Restaurant.fromFirestore(doc)).toList();
  }

  /// Guardar restaurante con ID específico
  Future<void> saveRestaurantWithId(String id, Restaurant restaurant) async {
    await _db.collection("Restaurants").doc(id).set(restaurant.toMap());
  }

  /// Subir imagen y obtener URL
  Future<String> uploadImage(String restaurantId, File imageFile) async {
    final ref = _storage.ref().child("restaurants/$restaurantId.jpg");
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  /// Obtener restaurante por ID
  Future<Restaurant?> getRestaurantById(String id) async {
    final doc = await _db.collection("Restaurants").doc(id).get();
    if (!doc.exists) return null;
    return Restaurant.fromFirestore(doc);
  }

  /// Obtener favoritos una sola vez (Future)
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

  /// Escuchar cambios en los restaurantes favoritos (Stream)
  Stream<List<Restaurant>> getFavoriteRestaurantsStream(
      Map<String, Timestamp> favoritesMap) {
    if (favoritesMap.isEmpty) {
      return const Stream.empty();
    }

    final ids = favoritesMap.keys.toList();

    return _db
        .collection("Restaurants")
        .where(FieldPath.documentId, whereIn: ids)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Restaurant.fromFirestore(doc)).toList());
  }
}
