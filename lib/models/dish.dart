import 'package:cloud_firestore/cloud_firestore.dart';
class Dish {
  final String id;
  final String name;
  final double price;
  final int rating;
  final String description;
  final String imageUrl;
  final String restaurantId;
  final List<String> dishesTags;
  final String dishType;

  Dish({
    required this.id,
    required this.name,
    required this.price,
    required this.rating,
    required this.description,
    required this.imageUrl,
    required this.restaurantId,
    required this.dishesTags,
    required this.dishType,
  });

  /// Crear Dish desde un documento de Firestore
  factory Dish.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Dish(
      id: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      rating: (data['rating'] ?? 0).toInt(),
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      dishesTags: List<String>.from(data['dishesTags'] ?? []),
      dishType: data['dishType'] ?? '',
    );
  }

  /// Convertir Dish a un Map (para guardar en Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'rating': rating,
      'description': description,
      'imageUrl': imageUrl,
      'restaurantId': restaurantId,
      'dishesTags': dishesTags,
      'dishType': dishType,
    };
  }

  /// Copiar Dish modificando solo lo necesario
  Dish copyWith({
    String? id,
    String? name,
    double? price,
    int? rating,
    String? description,
    String? imageUrl,
    String? restaurantId,
    List<String>? dishesTags,
    String? dishType,
  }) {
    return Dish(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      restaurantId: restaurantId ?? this.restaurantId,
      dishesTags: dishesTags ?? this.dishesTags,
      dishType: dishType ?? this.dishType,
    );
  }
}
