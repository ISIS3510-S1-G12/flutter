import 'package:flutter/foundation.dart';
import 'package:moviles/models/review.dart';
import 'package:moviles/repositories/review_repository.dart';

class ReviewViewModel extends ChangeNotifier {
  final ReviewRepository _repository;
  List<Review> reviews = [];
  bool isLoading = false;
  String? photoUrl; // 👈 para guardar temporalmente la foto

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


  /// Tomar foto y subir a Storage
  Future<void> pickImage(String reviewId) async {
    isLoading = true;
    notifyListeners();

    photoUrl = await _repository.pickAndUploadImage(reviewId);

    isLoading = false;
    notifyListeners();
  }

  /// Crear reseña con foto opcional
  Future<void> addReview({
    required String comment,
    required int stars,
    required String userId,
    required String restaurantId,
  }) async {
    isLoading = true;
    notifyListeners();

    await _repository.addReview(
      comment: comment,
      stars: stars,
      userId: userId,
      restaurantId: restaurantId,
      photoUrl: photoUrl, // 👈 pasamos la URL si existe
    );

    // limpiamos foto temporal
    photoUrl = null;

    // 🔄 refrescamos lista después de agregar
    await loadReviews(restaurantId);

    isLoading = false;
    notifyListeners();
  }
}
