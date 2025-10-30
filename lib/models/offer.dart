import 'package:cloud_firestore/cloud_firestore.dart';

class Offer {
  final String? id; // ID en Firestore (puede ser null si es local)
  final int? localId; // ID local SQLite
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
  final bool synced;

  Offer({
    this.id,
    this.localId,
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
    this.synced = false,
  });

  // 🔹 Firestore -> Offer
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
      synced: true,
    );
  }

  // Offer -> Firestore map
  Map<String, dynamic> toMap() {
    return {
      "restaurant_id": restaurant_id,
      "title": title,
      "description": description,
      "discount_percentage": discount_percentage,
      "price": price,
      "image": image,
      "tags": tags,
      "valid_from":
          valid_from != null ? Timestamp.fromDate(valid_from!) : null,
      "valid_to": valid_to != null ? Timestamp.fromDate(valid_to!) : null,
      "createdAt": Timestamp.fromDate(createdAt),
    };
  }

  // 🔹 SQLite map (local)
  Map<String, dynamic> toLocalMap() {
    return {
      'localId': localId,
      'restaurant_id': restaurant_id,
      'title': title,
      'description': description,
      'discount_percentage': discount_percentage,
      'price': price,
      'image': image,
      'tags': tags?.join(',') ?? '',
      'valid_from': valid_from?.toIso8601String(),
      'valid_to': valid_to?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  // SQLite -> Offer
  factory Offer.fromLocalMap(Map<String, dynamic> map) {
    return Offer(
      localId: map['localId'] is int ? map['localId'] as int : int.tryParse(map['localId'].toString()),
      restaurant_id: map['restaurant_id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      discount_percentage:
          (map['discount_percentage'] as num?)?.toDouble() ?? 0.0,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      image: map['image'],
      tags: (map['tags'] as String?)?.isNotEmpty == true
          ? (map['tags'] as String).split(',').map((s) => s.trim()).toList()
          : null,
      valid_from: map['valid_from'] != null
          ? DateTime.tryParse(map['valid_from'])
          : null,
      valid_to: map['valid_to'] != null
          ? DateTime.tryParse(map['valid_to'])
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      synced: (map['synced'] ?? 0) == 1,
    );
  }

  // 🔹 copyWith (restaurado)
  Offer copyWith({
    String? id,
    int? localId,
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
    bool? synced,
  }) {
    return Offer(
      id: id ?? this.id,
      localId: localId ?? this.localId,
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
      synced: synced ?? this.synced,
    );
  }
}
