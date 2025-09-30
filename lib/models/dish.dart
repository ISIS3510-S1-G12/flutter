import 'package:cloud_firestore/cloud_firestore.dart';

class Dish {
  final String id;
  final String restaurantId;
  final String name;
  final double price;
  final int rating;
  final String imageUrl; 
  final String description;     // Nuevo
  final String dishType;        // Nuevo
  final List<String> dishesTags; // Nuevo

  Dish({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.price,
    required this.rating,
    required this.imageUrl,
    required this.description,
    required this.dishType,
    required this.dishesTags,
  });

  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'name': name,
      'price': price,
      'rating': rating,
      'imageUrl': imageUrl,
      'description': description,
      'dishType': dishType,
      'dishesTags': dishesTags,
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
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      dishType: data['dishType'] ?? '',
      dishesTags: data['dishesTags'] != null
          ? List<String>.from(data['dishesTags'])
          : [],
    );
  }
}
