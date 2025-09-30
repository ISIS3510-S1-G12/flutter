import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moviles/models/review.dart' show Review;

class ReviewRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// 📸 Tomar foto con cámara y subir a Firebase Storage
  Future<String?> pickAndUploadImage(String reviewId) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return null;

    final ref = _storage.ref().child("reviews/$reviewId.jpg");
    await ref.putFile(File(image.path));

    return await ref.getDownloadURL();
  }

  /// 📝 Guardar review en Firestore (con plato opcional y foto opcional)
  Future<void> addReview({
    required String comment,
    required int stars,
    required String userId,
    required String restaurantId,
    String? dishId,   // 🔹 nuevo parámetro opcional
    String? photoUrl,
  }) async {
    await _db.collection("Reviews").add({
      "comment": comment,
      "stars": stars,
      "dish_id": dishId != null
          ? _db.collection("Dishes").doc(dishId)
          : null, // 🔹 guarda referencia si existe
      "photoUrl": photoUrl,
      "restaurant_id": _db.collection("Restaurants").doc(restaurantId),
      "user_id": _db.collection("Users").doc(userId),
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  /// 🍴 Obtener todas las reviews de un restaurante
  Future<List<Review>> getReviewsByRestaurant(String restaurantId) async {
    final snapshot = await _db
        .collection("Reviews")
        .where(
          "restaurant_id",
          isEqualTo: _db.collection("Restaurants").doc(restaurantId),
        )
        .get();

    return snapshot.docs
        .map((doc) => Review.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// 👤 Obtener todas las reviews hechas por un usuario
  Future<List<Review>> getReviewsByUser(String userId) async {
    final snapshot = await _db
        .collection("Reviews")
        .where(
          "user_id",
          isEqualTo: _db.collection("Users").doc(userId),
        )
        .get();

    return snapshot.docs
        .map((doc) => Review.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// 🍽 Obtener todas las reviews asociadas a un plato específico
  Future<List<Review>> getReviewsByDish(String dishId) async {
    final snapshot = await _db
        .collection("Reviews")
        .where(
          "dish_id",
          isEqualTo: _db.collection("Dishes").doc(dishId),
        )
        .get();

    return snapshot.docs
        .map((doc) => Review.fromFirestore(doc.id, doc.data()))
        .toList();
  }
}
