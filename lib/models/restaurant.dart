import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {
  final String id;
  final String name;
  final String typeOfFood;
  final String address;
  final String email;
  final String imageUrl;
  final bool offer;
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
    required this.offer,
    required this.openingTime,
    required this.closingTime,
    this.busiestHours,
    required this.rating,
  });

  factory Restaurant.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Restaurant(
      id: doc.id,
      name: data?['name'] ?? '',
      typeOfFood: data?['typeOfFood'] ?? '',
      address: data?['address'] ?? '',
      email: data?['email'] ?? '',
      imageUrl: data?['imageUrl'] ?? '',
      offer: data?['offer'] == true,
      openingTime: data?['opening_time'] ?? 9,
      closingTime: data?['closing_time'] ?? 22,
      busiestHours: data?['busiest_hours'],
      rating: (data?['rating'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'typeOfFood': typeOfFood,
      'address': address,
      'email': email,
      'imageUrl': imageUrl,
      'offer': offer,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'busiest_hours': busiestHours,
      'rating': rating,
    };
  }
}
