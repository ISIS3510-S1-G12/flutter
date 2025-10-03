import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String ownerUid;
  final String role;
  final Map<String, dynamic> preferences;
  final Map<String, Timestamp> favoriteRestaurants; 
  final String? profilePicture;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.ownerUid,
    required this.role,
    required this.preferences,
    required this.favoriteRestaurants,
    this.profilePicture,
    this.createdAt,
    this.updatedAt,
  });

  /// fromFirestore
  factory User.fromFirestore(String id, Map<String, dynamic> data) {
    return User(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      ownerUid: data['ownerUid'] ?? '',
      role: data['role'] ?? 'user',
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
      favoriteRestaurants: Map<String, Timestamp>.from(
        data['favorite_restaurants'] ?? {},
      ),
      profilePicture: data['profile_picture'],
      createdAt: data['created_at'],
      updatedAt: data['updated_at'],
    );
  }


  /// toFirestore
  Map<String, dynamic> toFirestore() {
    return {
      "name": name,
      "email": email,
      "ownerUid": ownerUid,
      "role": role,
      "preferences": preferences,
      "favorite_restaurants": favoriteRestaurants,
      "profile_picture": profilePicture,
      "created_at": createdAt ?? FieldValue.serverTimestamp(),
      "updated_at": FieldValue.serverTimestamp(),
    };
  }
}
