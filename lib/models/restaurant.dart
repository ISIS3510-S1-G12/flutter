import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {
  final String id;
  final String name;
  final String typeOfFood;
  final String address;
  final String email;
  final String imageUrl;
  final bool offer; // 🔹 ahora es boolean
  final int openingTime;
  final int closingTime;
  final Map<String, dynamic>? busiestHours;
  final double rating;

  Restaurant({
    required this.id,
    required this.name,
    required this.typeOfFood,
    required this.address,
    required this.email,
    required this.imageUrl,
    required this.offer, // 🔹 requerido y boolean
    required this.openingTime,
    required this.closingTime,
    this.busiestHours,
    required this.rating,
  });

  factory Restaurant.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    print("Documento Firestore [${doc.id}]: $data"); // Debug

    return Restaurant(
      id: doc.id,
      name: data?['name'] ?? '',
      typeOfFood: data?['typeOfFood']?.toString() ?? '',
      address: data?['address']?.toString() ?? '',
      email: data?['email']?.toString() ?? '',
      imageUrl: data?['imageUrl'] ?? '',
      openingTime: int.tryParse(data?['opening_time']?.toString() ?? '0') ?? 0,
      closingTime: int.tryParse(data?['closing_time']?.toString() ?? '0') ?? 0,
      busiestHours: data?['busiest_hours'],
      rating: double.tryParse(data?['rating']?.toString() ?? '0') ?? 0.0,
      offer: data?['offer'] == true, // 🔹 siempre bool
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'typeOfFood': typeOfFood,
      'address': address,
      'email': email,
      'imageUrl': imageUrl,
      'offer': offer, // 🔹 bool
      'opening_time': openingTime,
      'closing_time': closingTime,
      'busiest_hours': busiestHours,
      'rating': rating,
    };
  }
}
