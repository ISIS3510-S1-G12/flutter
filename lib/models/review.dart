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

  /// ✅ Este ya lo tenías, solo ajustamos las llaves para mantener consistencia
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "comment": comment,
      "stars": stars,
      "userId": userId,
      "restaurantId": restaurantId,
      "dishId": dishId,
      "imageUrl": imageUrl,
      "createdAt": createdAt?.toIso8601String(),
    };
  }

  /// ✅ Agrega este para reconstruir desde Hive / JSON local
  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json["id"] ?? "",
      comment: json["comment"] ?? "",
      stars: json["stars"] ?? 0,
      userId: json["userId"] ?? "",
      restaurantId: json["restaurantId"] ?? "",
      dishId: json["dishId"],
      imageUrl: json["imageUrl"],
      createdAt: json["createdAt"] != null
          ? DateTime.tryParse(json["createdAt"])
          : null,
    );
  }
}
