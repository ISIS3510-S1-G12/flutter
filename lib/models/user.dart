// models/user.dart
class User {
  final String id; // el docId en Firestore
  final String email;
  final String name;
  final String profilePicture;
  final List<String> favoriteRestaurants;
  final Map<String, dynamic> preferences;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.profilePicture,
    required this.favoriteRestaurants,
    required this.preferences,
  });

  // Convertir desde documento Firestore
  factory User.fromFirestore(String id, Map<String, dynamic> data) {
    return User(
      id: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      profilePicture: data['profile_picture'] ?? '',
      favoriteRestaurants:
          List<String>.from(data['favorite_restaurants'] ?? []),
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
    );
  }

  // Convertir a JSON para guardar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      "email": email,
      "name": name,
      "profile_picture": profilePicture,
      "favorite_restaurants": favoriteRestaurants,
      "preferences": preferences,
    };
  }
}
