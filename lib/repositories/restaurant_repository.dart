// repositories/restaurant_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/restaurant.dart';

class RestaurantRepository {
  final _db = FirebaseFirestore.instance;

  /// Obtener todos los restaurantes de Firestore
  Future<List<Restaurant>> getRestaurants() async {
    final snapshot = await _db.collection("Restaurants").get();

    return snapshot.docs
        .map((doc) => Restaurant.fromFirestore(doc)) // ✅ se pasa el doc directamente
        .toList();
  }

  /// Agregar un restaurante nuevo
  Future<void> addRestaurant(Restaurant restaurant) async {
    await _db.collection("Restaurants").add(restaurant.toMap());
  }

  /// Obtener restaurante por ID
  Future<Restaurant?> getRestaurantById(String id) async {
    final doc = await _db.collection("Restaurants").doc(id).get();
    if (!doc.exists) return null;
    return Restaurant.fromFirestore(doc); // ✅ ya no hace falta cast forzado
  }
}
