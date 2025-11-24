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

  static void removeFromRestaurant(String restaurantId, String reviewId) {
    final list = _byRestaurant[restaurantId];
    if (list != null) {
      list.removeWhere((r) => r.id == reviewId);
      if (list.isEmpty) _byRestaurant.remove(restaurantId);
    }
  }

  /// --- CACHE POR USUARIO ---
  static List<Review>? getByUser(String userId) => _byUser[userId];

  static void putByUser(String userId, List<Review> reviews) {
    _byUser[userId] = reviews;
  }

  static void removeFromUser(String userId, String reviewId) {
    final list = _byUser[userId];
    if (list != null) {
      list.removeWhere((r) => r.id == reviewId);
      if (list.isEmpty) _byUser.remove(userId);
    }
  }

  /// --- CACHE POR PLATO ---
  static List<Review>? getByDish(String dishId) => _byDish[dishId];

  static void putByDish(String dishId, List<Review> reviews) {
    _byDish[dishId] = reviews;
  }

  static void removeFromDish(String dishId, String reviewId) {
    final list = _byDish[dishId];
    if (list != null) {
      list.removeWhere((r) => r.id == reviewId);
      if (list.isEmpty) _byDish.remove(dishId);
    }
  }

  /// --- LIMPIAR TODO ---
  static void clear() {
    _byRestaurant.clear();
    _byUser.clear();
    _byDish.clear();
  }
}