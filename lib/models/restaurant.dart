import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {
  final String id; // 👈 este viene del doc.id
  final String name;
  final String typeOfFood;
  final double rating;
  final String offer;
  final String imageUrl;

  Restaurant({
    required this.id,
    required this.name,
    required this.typeOfFood,
    required this.rating,
    required this.offer,
    required this.imageUrl,
  });

  // Factory para construir desde Firestore
  factory Restaurant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Restaurant(
      id: doc.id, // 👈 usamos el id del documento
      name: data['name'] ?? '',
      typeOfFood: data['restaurant_type'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      offer: data['offer'] ?? '',
      imageUrl: data['restaurant_image'] ?? '',
    );
  }
}
