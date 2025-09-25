import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String comment;
  final int stars;
  final String userId;
  final String restaurantId;
  final String? photoUrl;

  Review({
    required this.id,
    required this.comment,
    required this.stars,
    required this.userId,
    required this.restaurantId,
    this.photoUrl,
  });

  factory Review.fromFirestore(String id, Map<String, dynamic> data) {
    return Review(
      id: id,
      comment: data["comment"] ?? "",
      stars: data["stars"] ?? 0,
      userId: (data["user_id"] as DocumentReference).id,
      restaurantId: (data["restaurant_id"] as DocumentReference).id,
      photoUrl: data["photoUrl"],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "comment": comment,
      "stars": stars,
      "user_id": FirebaseFirestore.instance.doc("users/$userId"),
      "restaurant_id": FirebaseFirestore.instance.doc("restaurants/$restaurantId"),
      "photoUrl": photoUrl,
    };
  }
}
