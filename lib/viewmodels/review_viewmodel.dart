import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:moviles/models/review.dart';
import 'package:moviles/repositories/review_repository.dart';

// Nuevos imports para cache y almacenamiento local
import 'package:moviles/repositories/local_review_db.dart'; // SQLite
import 'package:moviles/repositories/hive_review_cache.dart'; // Hive
import 'package:moviles/repositories/local_image_storage.dart'; // Archivos locales
import 'package:moviles/repositories/restaurant_preferences.dart'; // SharedPreferences

class ReviewViewModel extends ChangeNotifier { 
  final ReviewRepository _repository;

  final LocalReviewDB _localDB = LocalReviewDB();
  final HiveReviewCache _hiveCache = HiveReviewCache();
  final LocalImageStorage _imageStorage = LocalImageStorage();
  final RestaurantPreferences _prefs = RestaurantPreferences();

  List<Review> reviews = [];
  bool isLoading = false;
  String? imageUrl;

  ReviewViewModel(this._repository);

  Future<void> loadReviews(String restaurantId) async {
    isLoading = true;
    notifyListeners();

    try {
      reviews = await _repository.getReviewsByRestaurant(restaurantId);
      await _hiveCache.cacheReviews(restaurantId, reviews);
      for (var r in reviews) {
        await _localDB.insertReview(r);
      }
    } catch (e) {
      reviews = await _hiveCache.getCachedReviews(restaurantId);
      if (reviews.isEmpty) {
        reviews = await _localDB.getReviewsByRestaurant(restaurantId);
      }
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadReviewsByUser(String userId) async {
    isLoading = true;
    notifyListeners();

    reviews = await _repository.getReviewsByUser(userId);

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadReviewsByDish(String dishId) async {
    isLoading = true;
    notifyListeners();

    reviews = await _repository.getReviewsByDish(dishId);

    isLoading = false;
    notifyListeners();
  }

  Future<void> pickImage(String reviewId) async {
    isLoading = true;
    notifyListeners();

    imageUrl = await _imageStorage.pickAndSaveImage(reviewId);

    isLoading = false;
    notifyListeners();
  } 

  Future<void> addReview({
    required String comment,
    required int stars,
    required String userId,
    required String restaurantId,
    String? dishId,
  }) async {
    isLoading = true;
    notifyListeners();

    await _repository.addReview(
      comment: comment,
      stars: stars,
      userId: userId,
      restaurantId: restaurantId,
      dishId: dishId,
      imageUrl: imageUrl,
    );

    await _prefs.saveLastRestaurant(restaurantId);
    imageUrl = null;

    await loadReviews(restaurantId);

    isLoading = false;
    notifyListeners();
  }

  Future<String?> getLastRestaurant() async {
    return await _prefs.getLastRestaurant();
  }

  Future<void> updateReview({
  required String reviewId,
  required String restaurantId,
  required String comment,
  required int stars,
  String? imageUrl,
}) async {
  try {
    isLoading = true;
    notifyListeners();

    // 1️⃣ Actualizar en Firestore
    await _repository.updateReview(
      reviewId: reviewId,
      restaurantId: restaurantId,
      comment: comment,
      stars: stars,
      imageUrl: imageUrl,
    );

    // 2️⃣ Actualizar cache local en RAM
    final index = reviews.indexWhere((r) => r.id == reviewId);
    if (index != -1) {
      reviews[index] = Review(
        id: reviewId,
        comment: comment,
        stars: stars,
        userId: reviews[index].userId,
        restaurantId: restaurantId,
        dishId: reviews[index].dishId,
        imageUrl: imageUrl,
        createdAt: reviews[index].createdAt,
      );
    }

    // 3️⃣ Recargar la UI
    notifyListeners();

  } catch (e) {
    print("Error updating review: $e");
  } finally {
    isLoading = false;
    notifyListeners();
  }
}






}
