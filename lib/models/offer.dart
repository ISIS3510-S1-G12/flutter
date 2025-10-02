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
  final DateTime createdAt;

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
    required this.createdAt,
  });

  /// 🔹 Crear Offer desde Firestore
  factory Offer.fromMap(Map<String, dynamic> map, String id) {
    return Offer(
      id: id,
      restaurantId: map['restaurantId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      discountPercentage: (map['discountPercentage'] ?? 0).toDouble(),
      image: map['image'],
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
      validFrom: map['validFrom'] != null
          ? (map['validFrom'] as Timestamp).toDate()
          : null,
      validTo: map['validTo'] != null
          ? (map['validTo'] as Timestamp).toDate()
          : null,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// 🔹 Convertir Offer a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "restaurantId": restaurantId,
      "title": title,
      "description": description,
      "discountPercentage": discountPercentage,
      "image": image,
      "tags": tags,
      "validFrom": validFrom != null ? Timestamp.fromDate(validFrom!) : null,
      "validTo": validTo != null ? Timestamp.fromDate(validTo!) : null,
      "createdAt": Timestamp.fromDate(createdAt),
    };
  }

  /// 🔹 Copiar y actualizar
  Offer copyWith({
    String? id,
    String? restaurantId,
    String? title,
    String? description,
    double? discountPercentage,
    String? image,
    List<String>? tags,
    DateTime? validFrom,
    DateTime? validTo,
    DateTime? createdAt,
  }) {
    return Offer(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      title: title ?? this.title,
      description: description ?? this.description,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      image: image ?? this.image,
      tags: tags ?? this.tags,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
