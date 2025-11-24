// lib/viewmodels/review_viewmodel.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:moviles/models/review.dart';
import 'package:moviles/repositories/review_repository.dart';
import 'package:moviles/repositories/local_review_db.dart';
import 'package:moviles/utils/review_isolate_helpers.dart'; // ← NECESARIO

class ReviewViewModel extends ChangeNotifier {
  // ============= CAMPOS NECESARIOS =============
  final ReviewRepository _repository;
  final LocalReviewDB _localDB = LocalReviewDB();

  List<Review> reviews = [];
  bool isLoading = false;
  String? errorMessage;  // mensajes de error
  String? infoMessage;   // mensajes informativos (offline/pending/online)

  StreamSubscription<bool>? _connectivitySub;
   // Nuevo: stream público
  Stream<bool> get connectivityStream => _repository.connectivityStream;

  ReviewViewModel(this._repository) {
    initConnectivitySync();
  }

  // ============================================================
  // CARGAS ORIGINALES (NO SE TOCAN)
  // ============================================================
  Future<void> loadReviewsByRestaurant(String restaurantId) async {
    isLoading = true;
    notifyListeners();
    try {
      final hasInternet = await _repository.hasConnection();
      if (hasInternet) {
        reviews = await _repository.getReviewsByRestaurant(restaurantId);

        final serial = await compute(
            serializeReviewsForLocal, reviews.map((r) => r.toJson()).toList());

        await _localDB.saveReviews(reviews);
      } else {
        reviews = await _localDB.getReviewsByRestaurant(restaurantId);
      }
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
      reviews = [];
    }
    isLoading = false;
    notifyListeners();
  }

  // ============================================================
  // UPDATE REVIEW (eventual connectivity + mensajes)
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
      final hasInternet = await _repository.hasConnection();

      if (!hasInternet) {
        // Guardar actualización offline
        final updateMap = {
          "reviewId": reviewId,
          "comment": comment,
          "stars": stars,
          "imageUrl": imageUrl,
        };

        await compute(savePendingUpdateIsolatePayload, updateMap);
        await _localDB.savePendingUpdate(updateMap);

        final idx = reviews.indexWhere((r) => r.id == reviewId);
        if (idx != -1) {
          reviews[idx] = Review(
            id: reviewId,
            comment: comment,
            stars: stars,
            userId: reviews[idx].userId,
            restaurantId: restaurantId,
            dishId: reviews[idx].dishId,
            imageUrl: imageUrl,
            createdAt: reviews[idx].createdAt,
          );
        }

        // ← Asignar infoMessage offline
        infoMessage = "No connection: review will be sent when online.";
        debugPrint("Saved pending update for review $reviewId (offline).");
        notifyListeners();
        return;
      }

      // Online → actualizar en Firestore
      await _repository.updateReview(
        reviewId: reviewId,
        comment: comment,
        stars: stars,
        imageUrl: imageUrl,
      );

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

      // ← Asignar infoMessage online
      infoMessage = "Review updated online!";
      debugPrint("Review $reviewId updated ONLINE.");
      notifyListeners();
    } catch (e) {
      errorMessage = "Error updating review: $e";
      debugPrint(errorMessage);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // SYNC AUTOMÁTICO (con infoMessage)
  // ============================================================
  void initConnectivitySync() {
    _connectivitySub?.cancel();
    _connectivitySub = _repository.connectivityStream.listen((isOnline) async {
      if (!isOnline) {
        infoMessage = "No connection: pending updates will be sent when online.";
        notifyListeners();
        return;
      }

      if (infoMessage != null) {
        infoMessage = "Connection restored. Sending pending updates...";
        notifyListeners();
      }

      try {
        final pendings = await _localDB.getPendingUpdates();
        if (pendings.isEmpty) {
          infoMessage = null;
          notifyListeners();
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

        infoMessage = "All pending updates sent!";
        notifyListeners();
      } catch (e) {
        debugPrint("Error while syncing pending updates: $e");
      }
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  // ============================================================
  // MÉTODO EXTRA loadReviews simple
  // ============================================================
  Future<void> loadReviews(String restaurantId) async {
    try {
      isLoading = true;
      notifyListeners();

      final fetched = await _repository.getReviewsByRestaurant(restaurantId);
      reviews = fetched;
      notifyListeners();
    } catch (e) {
      errorMessage = "Error cargando reseñas: $e";
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  // Al final de tu clase ReviewViewModel
Future<bool> get hasConnection async {
  return await _repository.hasConnection();
}

// Dentro de ReviewViewModel
Future<bool> checkConnection() async {
  return await _repository.hasConnection();
}


}
