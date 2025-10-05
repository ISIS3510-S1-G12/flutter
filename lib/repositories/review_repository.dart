import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moviles/models/review.dart' show Review;

class ReviewRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickAndUploadImage(String reviewId) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return null;

    final ref = _storage.ref().child("reviews/$reviewId.jpg");
    await ref.putFile(File(image.path));

    return await ref.getDownloadURL();
  }

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

  Future<List<Review>> getReviewsByRestaurant(String restaurantId) async {
    final snapshot = await _db
        .collection("Reviews")
        .where("restaurant_id", isEqualTo: restaurantId)
        .get();

    return snapshot.docs
        .map((doc) => Review.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  Future<List<Review>> getReviewsByUser(String userId) async {
    final snapshot = await _db
        .collection("Reviews")
        .where("user_id", isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => Review.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  Future<List<Review>> getReviewsByDish(String dishId) async {
    final snapshot = await _db
        .collection("Reviews")
        .where("dish_id", isEqualTo: dishId)
        .get();

    return snapshot.docs
        .map((doc) => Review.fromFirestore(doc.id, doc.data()))
        .toList();
  }
}
