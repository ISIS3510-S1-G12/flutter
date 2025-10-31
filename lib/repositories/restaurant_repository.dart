import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/restaurant.dart';
import '../../cache/restaurant_cache.dart'; 

class RestaurantRepository {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  ///  Obtener todos los restaurantes (una sola vez)
  Future<List<Restaurant>> getRestaurants() async {
    final snapshot = await _db.collection("Restaurants").get();
    final restaurants =
        snapshot.docs.map((doc) => Restaurant.fromFirestore(doc)).toList();

    // Guardar en cache
    for (final r in restaurants) {
      RestaurantCache.put(r.id, r);
    }
    return restaurants;
  }

  ///  Guardar restaurante con ID específico
  Future<void> saveRestaurantWithId(String id, Restaurant restaurant) async {
    await _db.collection("Restaurants").doc(id).set(restaurant.toMap());
    RestaurantCache.put(id, restaurant); //  Actualizar cache también
  }

  ///  Subir imagen y obtener URL
  Future<String> uploadImage(String restaurantId, File imageFile) async {
    final ref = _storage.ref().child("restaurants/$restaurantId.jpg");
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  ///  Obtener restaurante por ID (usa cache → Firestore)
  Future<Restaurant?> getRestaurantById(String id) async {
    //  Buscar primero en cache
    final cached = RestaurantCache.get(id);
    if (cached != null) {
      print(" [LRU] Restaurante obtenido desde cache: ${cached.name}");
      return cached;
    }

    //  Si no está, buscar en Firestore
    try {
      final doc = await _db.collection("Restaurants").doc(id).get();
      if (!doc.exists) return null;

      final restaurant = Restaurant.fromFirestore(doc);
      RestaurantCache.put(id, restaurant);
      print(" [Firestore] Restaurante cargado y cacheado: ${restaurant.name}");
      return restaurant;
    } catch (e) {
      print(" Error al obtener restaurante: $e");
      return null;
    }
  }

  ///  Obtener favoritos una sola vez (Future)
  Future<List<Restaurant>> getFavoriteRestaurants(
      Map<String, Timestamp> favoritesMap) async {
    if (favoritesMap.isEmpty) return [];

    final ids = favoritesMap.keys.toList();

    // Intentar obtener de cache primero
    final cached = ids
        .map((id) => RestaurantCache.get(id))
        .whereType<Restaurant>()
        .toList();

    // Buscar los que no están cacheados
    final missingIds = ids.where((id) => !RestaurantCache.contains(id)).toList();

    if (missingIds.isEmpty) {
      print(" [LRU] Todos los favoritos desde cache");
      return cached;
    }

    // Cargar los faltantes desde Firestore
    final snapshot = await _db
        .collection("Restaurants")
        .where(FieldPath.documentId, whereIn: missingIds)
        .get();

    final fetched =
        snapshot.docs.map((doc) => Restaurant.fromFirestore(doc)).toList();

    // Guardar nuevos en cache
    for (final r in fetched) {
      RestaurantCache.put(r.id, r);
    }

    print(" [Firestore] ${fetched.length} restaurantes cacheados nuevos");

    // Combinar cache + nuevos
    return [...cached, ...fetched];
  }

  ///  Escuchar cambios en los restaurantes favoritos (Stream)
  Stream<List<Restaurant>> getFavoriteRestaurantsStream(
      Map<String, Timestamp> favoritesMap) {
    if (favoritesMap.isEmpty) return const Stream.empty();

    final ids = favoritesMap.keys.toList();

    return _db
        .collection("Restaurants")
        .where(FieldPath.documentId, whereIn: ids)
        .snapshots()
        .map((snapshot) {
      final list =
          snapshot.docs.map((doc) => Restaurant.fromFirestore(doc)).toList();

      // Actualizar cache en tiempo real
      for (final r in list) {
        RestaurantCache.put(r.id, r);
      }
      return list;
    });
  }
}
