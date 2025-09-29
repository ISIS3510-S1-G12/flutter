import 'package:cloud_firestore/cloud_firestore.dart';

class Dish {
  final String id;
  final String restaurantId;
  final String name;
  final double price;
  final int rating;
  final String imageUrl; // <-- Cambiado de imageBase64 a imageUrl

  Dish({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.price,
    required this.rating,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'name': name,
      'price': price,
      'rating': rating,
      'imageUrl': imageUrl, // <-- Guardar URL
    };
  }

  factory Dish.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Dish(
      id: doc.id,
      restaurantId: data['restaurantId'] ?? '',
      name: data['name'] ?? '',
      price: (data['price'] as num).toDouble(),
      rating: (data['rating'] as num).toInt(),
      imageUrl: data['imageUrl'] ?? '', // <-- Leer URL
    );
  }
}
