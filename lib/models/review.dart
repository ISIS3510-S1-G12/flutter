import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String comment;
  final int stars;
  final String userId;
  final String restaurantId;
  final String? dishId;
  final String? imageUrl;
  final DateTime? createdAt;

  Review({
    required this.id,
    required this.comment,
    required this.stars,
    required this.userId,
    required this.restaurantId,
    this.dishId,
    this.imageUrl,
    this.createdAt,
  });

  factory Review.fromFirestore(String id, Map<String, dynamic> data) {
    return Review(
      id: id,
      comment: data["comment"] ?? "",
      stars: data["stars"] ?? 0,
      userId: data["user_id"] ?? "",
      restaurantId: data["restaurant_id"] ?? "",
      dishId: data["dish_id"],
      imageUrl: data["imageUrl"],
      createdAt: (data["createdAt"] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "comment": comment,
      "stars": stars,
      "user_id": userId,
      "restaurant_id": restaurantId,
      "dish_id": dishId,
      "imageUrl": imageUrl,
      "createdAt": createdAt,
    };
  }
}
