// lib/viewmodels/review_viewmodel.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:moviles/models/review.dart';
import 'package:moviles/repositories/review_repository.dart';
import 'package:moviles/repositories/local_review_db.dart';
import 'package:moviles/utils/review_isolate_helpers.dart';

class ReviewViewModel extends ChangeNotifier {
  final ReviewRepository _repository;
  final LocalReviewDB _localDB = LocalReviewDB();

  List<Review> reviews = [];
  bool isLoading = false;
  String? errorMessage;
  String? infoMessage;

  StreamSubscription<bool>? _connectivitySub;
  Stream<bool> get connectivityStream => _repository.connectivityStream;

  ReviewViewModel(this._repository) {
    initConnectivitySync();
  }

  // ============================================================
  // Helpers internos
  // ============================================================
  void _updateReviewInList(int index, Review oldReview,
      {required String comment, required int stars, String? imageUrl}) {
    reviews[index] = Review(
      id: oldReview.id,
      userId: oldReview.userId,
      restaurantId: oldReview.restaurantId,
      dishId: oldReview.dishId,
      createdAt: oldReview.createdAt,
      comment: comment,
      stars: stars,
      imageUrl: imageUrl,
    );
  }

  void _setInfo(String? msg) {
    if (infoMessage != msg) {
      infoMessage = msg;
      notifyListeners();
    }
  }

  // ============================================================
  // CARGAS DE REVIEWS
  // ============================================================
  Future<void> loadReviewsByRestaurant(String restaurantId) async {
    isLoading = true;
    notifyListeners();

    try {
      final online = await _repository.hasConnection();
      if (online) {
        reviews = await _repository.getReviewsByRestaurant(restaurantId);

        await compute(
          serializeReviewsForLocal,
          reviews.map((r) => r.toJson()).toList(),
        );

        await _localDB.saveReviews(reviews);
      } else {
        reviews = await _localDB.getReviewsByRestaurant(restaurantId);
      }
    } catch (_) {
      try {
        reviews = await _localDB.getReviewsByRestaurant(restaurantId);
      } catch (_) {
        reviews = [];
      }
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadReviewsByUser(String userId) async {
    isLoading = true;
    notifyListeners();

    try {
      reviews = await _repository.getReviewsByUser(userId);
    } catch (_) {
      reviews = [];
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadReviewsByDish(String dishId) async {
    isLoading = true;
    notifyListeners();

    try {
      reviews = await _repository.getReviewsByDish(dishId);
    } catch (_) {
      reviews = [];
    }

    isLoading = false;
    notifyListeners();
  }

  // ============================================================
  // UPDATE REVIEW (offline + sincronización eventual)
  // ============================================================
  Future<void> updateReview({
    required String reviewId,
    required String restaurantId,
    required String comment,
    required int stars,
    String? imageUrl,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final online = await _repository.hasConnection();

      // ------------------------- OFFLINE ---------------------------
      if (!online) {
        final updateMap = {
          "reviewId": reviewId,
          "comment": comment,
          "stars": stars,
          "imageUrl": imageUrl,
        };

        await compute(savePendingUpdateIsolatePayload, updateMap);
        await _localDB.savePendingUpdate(updateMap);

        final index = reviews.indexWhere((r) => r.id == reviewId);
        if (index != -1) {
          _updateReviewInList(reviews.indexWhere((r) => r.id == reviewId),
              reviews[index],
              comment: comment, stars: stars, imageUrl: imageUrl);
        }

        _setInfo("No connection: review will be sent when online.");
        return;
      }

      // ------------------------- ONLINE ---------------------------
      await _repository.updateReview(
        reviewId: reviewId,
        comment: comment,
        stars: stars,
        imageUrl: imageUrl,
      );

      final index = reviews.indexWhere((r) => r.id == reviewId);
      if (index != -1) {
        _updateReviewInList(index, reviews[index],
            comment: comment, stars: stars, imageUrl: imageUrl);
      }

      _setInfo("Review updated online!");
    } catch (e) {
      errorMessage = "Error updating review: $e";
      debugPrint(errorMessage);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // SYNC AUTOMÁTICO
  // ============================================================
  void initConnectivitySync() {
    _connectivitySub?.cancel();

    _connectivitySub = _repository.connectivityStream.distinct().listen(
      (isOnline) async {
        if (!isOnline) {
          _setInfo("No connection: pending updates will be sent when online.");
          return;
        }

        _setInfo("Connection restored. Sending pending updates...");

        try {
          final pendings = await _localDB.getPendingUpdates();
          if (pendings.isEmpty) {
            _setInfo(null);
            return;
          }

          for (final p in pendings) {
            try {
              await _repository.updateReview(
                reviewId: p["reviewId"],
                comment: p["comment"],
                stars: p["stars"] ?? 0,
                imageUrl: p["imageUrl"],
              );

              await _localDB.clearPendingUpdate(p["reviewId"]);
              debugPrint("Synchronized pending update: ${p["reviewId"]}");
            } catch (e) {
              debugPrint("Failed to sync ${p["reviewId"]}: $e");
            }
          }

          _setInfo("All pending updates sent!");
        } catch (e) {
          debugPrint("Error syncing pending updates: $e");
        }
      },
    );
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  // ============================================================
  // MÉTODO EXTRA simple
  // ============================================================
  Future<void> loadReviews(String restaurantId) async {
    isLoading = true;
    notifyListeners();

    try {
      reviews = await _repository.getReviewsByRestaurant(restaurantId);
    } catch (e) {
      errorMessage = "Error cargando reseñas: $e";
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> get hasConnection async => _repository.hasConnection();

  Future<bool> checkConnection() async => _repository.hasConnection();
}
