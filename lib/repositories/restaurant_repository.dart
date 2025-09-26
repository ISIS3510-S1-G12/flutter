// repositories/restaurant_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/restaurant.dart';

class RestaurantRepository {
  final _db = FirebaseFirestore.instance;

  Future<List<Restaurant>> getRestaurants() async {
    final snapshot = await _db.collection("Restaurants").get();
    return snapshot.docs.map((doc) => Restaurant.fromFirestore(doc)).toList();
  }

  Future<void> addRestaurant(Restaurant restaurant) async {
    await _db.collection("Restaurants").add(restaurant.toMap());
  }
}
