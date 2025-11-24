// lib/repositories/review_repository.dart
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moviles/models/review.dart' show Review;
import 'review_cache.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ReviewRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Stream que notifica si hay conectividad (true = online)
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  ReviewRepository() {
    // Inicializar escucha de conectividad
    Connectivity().onConnectivityChanged.listen((result) {
      final online = result != ConnectivityResult.none;
      _connectivityController.add(online);
    });
    // push initial
    Connectivity().checkConnectivity().then((r) {
      _connectivityController.add(r != ConnectivityResult.none);
    });
  }

  Stream<bool> get connectivityStream => _connectivityController.stream;

  Future<bool> hasConnection() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// --- Subir imagen de reseña ---
  Future<String?> pickAndUploadImage(String reviewId) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return null;

    final ref = _storage.ref().child("reviews/$reviewId.jpg");
    await ref.putFile(File(image.path));

    return await ref.getDownloadURL();
  }

  /// --- Agregar reseña ---
  Future<void> addReview({
    required String comment,
    required int stars,
    required String userId,
    required String restaurantId,
    String? dishId,
    String? imageUrl,
  }) async {
    await _db.collection("Reviews").add({
      "comment": comment,
      "stars": stars,
      "dish_id": dishId,
      "imageUrl": imageUrl,
      "restaurant_id": restaurantId,
      "user_id": userId,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  /// --- Obtener reseñas por restaurante (usa cache → Firestore) ---
  Future<List<Review>> getReviewsByRestaurant(String restaurantId) async {
    final cached = ReviewCache.getByRestaurant(restaurantId);
    if (cached != null) {
      return cached;
    }

    final snapshot = await _db
        .collection("Reviews")
        .where("restaurant_id", isEqualTo: restaurantId)
        .get();

    final reviews = snapshot.docs
        .map((doc) => Review.fromFirestore(doc.id, doc.data()))
        .toList();

    ReviewCache.putByRestaurant(restaurantId, reviews);
    return reviews;
  }

  /// --- Obtener reseñas por usuario ---
  Future<List<Review>> getReviewsByUser(String userId) async {
    final cached = ReviewCache.getByUser(userId);
    if (cached != null) {
      return cached;
    }

    final snapshot = await _db
        .collection("Reviews")
        .where("user_id", isEqualTo: userId)
        .get();

    final reviews = snapshot.docs
        .map((doc) => Review.fromFirestore(doc.id, doc.data()))
        .toList();

    ReviewCache.putByUser(userId, reviews);
    return reviews;
  }

  /// --- Obtener reseñas por plato ---
  Future<List<Review>> getReviewsByDish(String dishId) async {
    final cached = ReviewCache.getByDish(dishId);
    if (cached != null) {
      return cached;
    }

    final snapshot = await _db
        .collection("Reviews")
        .where("dish_id", isEqualTo: dishId)
        .get();

    final reviews = snapshot.docs
        .map((doc) => Review.fromFirestore(doc.id, doc.data()))
        .toList();

    ReviewCache.putByDish(dishId, reviews);
    return reviews;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getAllReviewsRaw() async {
    final snapshot = await FirebaseFirestore.instance.collection("Reviews").get();
    return snapshot.docs;
  }

  /// --- Update review on Firestore ---
  Future<void> updateReview({
    required String reviewId,
    required String comment,
    required int stars,
    String? imageUrl,
  }) async {
    await _db.collection("Reviews").doc(reviewId).update({
      "comment": comment,
      "stars": stars,
      if (imageUrl != null) "imageUrl": imageUrl,
      "updatedAt": FieldValue.serverTimestamp(),
    });
    ReviewCache.clear();
  }

  void dispose() {
    try {
      _connectivityController.close();
    } catch (_) {}
  }
}
