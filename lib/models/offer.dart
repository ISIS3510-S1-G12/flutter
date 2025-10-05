import 'package:cloud_firestore/cloud_firestore.dart';

class Offer {
  final String id;
  final String restaurant_id;
  final String title;
  final String description;
  final double discount_percentage;
  final double price; 
  final String? image;
  final List<String>? tags;
  final DateTime? valid_from;
  final DateTime? valid_to;
  final DateTime createdAt;

  Offer({
    required this.id,
    required this.restaurant_id,
    required this.title,
    required this.description,
    required this.discount_percentage,
    required this.price,
    this.image,
    this.tags,
    this.valid_from,
    this.valid_to,
    required this.createdAt,
  });

  factory Offer.fromMap(Map<String, dynamic> map, String id) {
    return Offer(
      id: id,
      restaurant_id: map['restaurant_id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      discount_percentage: (map['discount_percentage'] ?? 0).toDouble(),
      price: (map['price'] ?? 0).toDouble(), 
      image: map['image'],
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
      valid_from: map['valid_from'] != null
          ? (map['valid_from'] as Timestamp).toDate()
          : null,
      valid_to: map['valid_to'] != null
          ? (map['valid_to'] as Timestamp).toDate()
          : null,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "restaurant_id": restaurant_id,
      "title": title,
      "description": description,
      "discount_percentage": discount_percentage,
      "price": price, 
      "image": image,
      "tags": tags,
      "valid_from": valid_from != null ? Timestamp.fromDate(valid_from!) : null,
      "valid_to": valid_to != null ? Timestamp.fromDate(valid_to!) : null,
      "createdAt": Timestamp.fromDate(createdAt),
    };
  }

  Offer copyWith({
    String? id,
    String? restaurant_id,
    String? title,
    String? description,
    double? discount_percentage,
    double? price, 
    String? image,
    List<String>? tags,
    DateTime? valid_from,
    DateTime? valid_to,
    DateTime? createdAt,
  }) {
    return Offer(
      id: id ?? this.id,
      restaurant_id: restaurant_id ?? this.restaurant_id,
      title: title ?? this.title,
      description: description ?? this.description,
      discount_percentage: discount_percentage ?? this.discount_percentage,
      price: price ?? this.price, 
      image: image ?? this.image,
      tags: tags ?? this.tags,
      valid_from: valid_from ?? this.valid_from,
      valid_to: valid_to ?? this.valid_to,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
