import 'package:flutter/foundation.dart';
import 'package:moviles/models/review.dart';
import 'package:moviles/repositories/review_repository.dart';

class ReviewViewModel extends ChangeNotifier {
  final ReviewRepository _repository;
  List<Review> reviews = [];
  bool isLoading = false;
  String? imageUrl; 

  ReviewViewModel(this._repository);

  Future<void> loadReviews(String restaurantId) async {
    isLoading = true;
    notifyListeners();

    reviews = await _repository.getReviewsByRestaurant(restaurantId);

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

  /// Tomar foto y subir a Storage
  Future<void> pickImage(String reviewId) async {
    isLoading = true;
    notifyListeners();

    imageUrl = await _repository.pickAndUploadImage(reviewId);

    isLoading = false;
    notifyListeners();
  }

  /// Crear reseña con foto opcional
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

    imageUrl = null;

    await loadReviews(restaurantId);

    isLoading = false;
    notifyListeners();
  }
}
