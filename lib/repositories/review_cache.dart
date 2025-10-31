// lib/cache/review_cache.dart
import 'package:moviles/models/review.dart';

class ReviewCache {
  static final Map<String, List<Review>> _byRestaurant = {};
  static final Map<String, List<Review>> _byUser = {};
  static final Map<String, List<Review>> _byDish = {};

  /// --- CACHE POR RESTAURANTE ---
  static List<Review>? getByRestaurant(String restaurantId) =>
      _byRestaurant[restaurantId];

  static void putByRestaurant(String restaurantId, List<Review> reviews) {
    _byRestaurant[restaurantId] = reviews;
  }

  /// --- CACHE POR USUARIO ---
  static List<Review>? getByUser(String userId) => _byUser[userId];

  static void putByUser(String userId, List<Review> reviews) {
    _byUser[userId] = reviews;
  }

  /// --- CACHE POR PLATO ---
  static List<Review>? getByDish(String dishId) => _byDish[dishId];

  static void putByDish(String dishId, List<Review> reviews) {
    _byDish[dishId] = reviews;
  }

  /// --- OPCIONAL: limpiar todo ---
  static void clear() {
    _byRestaurant.clear();
    _byUser.clear();
    _byDish.clear();
  }
}
