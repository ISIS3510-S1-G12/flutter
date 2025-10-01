import 'package:cloud_firestore/cloud_firestore.dart';

class Offer {
  final String id;
  final String restaurantId;
  final String title;
  final String description;
  final double discountPercentage;
  final String? image;
  final List<String>? tags;
  final DateTime? validFrom;
  final DateTime? validTo;
  final DateTime? createdAt;

  Offer({
    required this.id,
    required this.restaurantId,
    required this.title,
    required this.description,
    required this.discountPercentage,
    this.image,
    this.tags,
    this.validFrom,
    this.validTo,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "restaurant_id": FirebaseFirestore.instance
          .collection("Restaurants")
          .doc(restaurantId), // DocumentReference
      "title": title,
      "description": description,
      "discount_percentage": discountPercentage,
      "image": image,
      "tags": tags,
      "valid_from": validFrom,
      "valid_to": validTo,
      "createdAt": createdAt,
    };
  }

  factory Offer.fromMap(Map<String, dynamic> map, String id) {
    return Offer(
      id: id,
      restaurantId: (map["restaurant_id"] as DocumentReference).id,
      title: map["title"] ?? "",
      description: map["description"] ?? "",
      discountPercentage: (map["discount_percentage"] ?? 0).toDouble(),
      image: map["image"],
      tags: List<String>.from(map["tags"] ?? []),
      validFrom: (map["valid_from"] as Timestamp?)?.toDate(),
      validTo: (map["valid_to"] as Timestamp?)?.toDate(),
      createdAt: (map["createdAt"] as Timestamp?)?.toDate(),
    );
  }
}
