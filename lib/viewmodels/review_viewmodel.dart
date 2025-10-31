import 'package:flutter/foundation.dart';
import 'package:moviles/models/review.dart';
import 'package:moviles/repositories/review_repository.dart';

//  Nuevos imports para las 4 estrategias
import 'package:moviles/repositories/local_review_db.dart'; // SQLite
import 'package:moviles/repositories/hive_review_cache.dart'; // Hive
import 'package:moviles/repositories/local_image_storage.dart'; // Archivos locales
import 'package:moviles/repositories/restaurant_preferences.dart'; // SharedPreferences

class ReviewViewModel extends ChangeNotifier {
  final ReviewRepository _repository;

  //  Nuevos repos locales
  final LocalReviewDB _localDB = LocalReviewDB();
  final HiveReviewCache _hiveCache = HiveReviewCache();
  final LocalImageStorage _imageStorage = LocalImageStorage();
  final RestaurantPreferences _prefs = RestaurantPreferences();

  List<Review> reviews = [];
  bool isLoading = false;
  String? imageUrl;

  ReviewViewModel(this._repository);

  ///  Cargar reseñas (usa cache local si falla el servidor)
  Future<void> loadReviews(String restaurantId) async {
    isLoading = true;
    notifyListeners();

    try {
      // Intentar traer de Firebase
      reviews = await _repository.getReviewsByRestaurant(restaurantId);

      // Guardar en Hive (cache rápido)
      await _hiveCache.cacheReviews(restaurantId, reviews);

      // Guardar también en SQLite (base relacional)
      for (var r in reviews) {
        await _localDB.insertReview(r);
      }
    } catch (e) {
      // Si falla, intentar cargar del cache local
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

  ///  Tomar foto y guardarla localmente (además de subir a Storage si hay conexión)
  Future<void> pickImage(String reviewId) async {
    isLoading = true;
    notifyListeners();

    // Guardar la imagen localmente (si no hay red, igual funciona)
    imageUrl = await _imageStorage.pickAndSaveImage(reviewId);

    // También podrías intentar subirla a Storage si estás conectado
    // imageUrl = await _repository.pickAndUploadImage(reviewId);

    isLoading = false;
    notifyListeners();
  }

  ///  Crear reseña (y guardar última preferencia)
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

    // Guardar restaurante en preferencias
    await _prefs.saveLastRestaurant(restaurantId);

    imageUrl = null;

    await loadReviews(restaurantId);

    isLoading = false;
    notifyListeners();
  }

  ///  Obtener el último restaurante visitado
  Future<String?> getLastRestaurant() async {
    return await _prefs.getLastRestaurant();
  }
}
