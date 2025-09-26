import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moviles/models/review.dart' show Review;

class ReviewRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Tomar foto con cámara y subir a Firebase Storage
  Future<String?> pickAndUploadImage(String reviewId) async {
    // 1️⃣ abrir la cámara
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return null;

    // 2️⃣ subir a Storage
    final ref = _storage.ref().child("reviews/$reviewId.jpg");
    await ref.putFile(File(image.path));

    // 3️⃣ obtener URL pública
    return await ref.getDownloadURL();
  }

  /// Guardar review en Firestore (con foto opcional)
  Future<void> addReview({
    required String comment,
    required int stars,
    required String userId,
    required String restaurantId,
    String? photoUrl, // 🔑 nuevo parámetro
  }) async {
    await _db.collection("Reviews").add({
      "comment": comment,
      "stars": stars,
      "dish_id": null,
      "photoUrl": photoUrl, // 👈 guardamos la URL si existe
      "restaurant_id": _db.collection("Restaurants").doc(restaurantId),
      "user_id": _db.collection("Users").doc(userId),
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  /// Obtener todas las reviews de un restaurante
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

  /// Obtener todas las reviews hechas por un usuario
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

}
