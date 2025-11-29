import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:moviles/models/user.dart';
import 'package:moviles/repositories/user_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserViewModel extends ChangeNotifier {
  final UserRepository _repository;
  User? currentUser;
  bool isLoading = false;

  UserViewModel(this._repository);

  Future<void> updateProfilePicture(String uid, String filePath) async {
    final url = await _repository.uploadProfilePicture(uid, filePath);
    if (currentUser != null) {
      currentUser = User(
        id: currentUser!.id,
        name: currentUser!.name,
        email: currentUser!.email,
        ownerUid: currentUser!.ownerUid,
        role: currentUser!.role,
        preferences: currentUser!.preferences,
        favoriteRestaurants: currentUser!.favoriteRestaurants,
        profilePicture: url,
        createdAt: currentUser!.createdAt,
        updatedAt: currentUser!.updatedAt,
      );
      notifyListeners();
    }
  }

  Future<void> loadUser(String userId) async {
    isLoading = true;
    notifyListeners();

    currentUser = await _repository.getUser(userId);

    isLoading = false;
    notifyListeners();
  }

  Future<void> saveUser(User user) async {
    isLoading = true;
    notifyListeners();

    // 🚀 Si hay foto local (path válido), la subimos
    if (user.profilePicture != null &&
        user.profilePicture!.isNotEmpty &&
        File(user.profilePicture!).existsSync()) {
      final url =
          await _repository.uploadProfilePicture(user.id, user.profilePicture!);
      user = User(
        id: user.id,
        name: user.name,
        email: user.email,
        ownerUid: user.ownerUid,
        role: user.role,
        preferences: user.preferences,
        favoriteRestaurants: user.favoriteRestaurants,
        profilePicture: url, // URL de Storage
        createdAt: user.createdAt,
        updatedAt: Timestamp.now(),
      );
    }

    await _repository.saveUser(user);
    currentUser = user;

    isLoading = false;
    notifyListeners();
  }

  ///  Alternar favoritos con Timestamp
  Future<void> toggleFavoriteRestaurant(String restaurantId) async {
    if (currentUser == null) return;

    final favorites =
        Map<String, Timestamp>.from(currentUser!.favoriteRestaurants);
    final isFavorite = favorites.containsKey(restaurantId);

    if (isFavorite) {
      favorites.remove(restaurantId);
    } else {
      favorites[restaurantId] = Timestamp.now();
    }

    await _repository.updateFavorites(currentUser!.id, favorites);

    currentUser = User(
      id: currentUser!.id,
      name: currentUser!.name,
      email: currentUser!.email,
      ownerUid: currentUser!.ownerUid,
      role: currentUser!.role,
      preferences: currentUser!.preferences,
      favoriteRestaurants: favorites,
      profilePicture: currentUser!.profilePicture,
      createdAt: currentUser!.createdAt,
      updatedAt: Timestamp.now(),
    );

    notifyListeners();
  }

  ///  Getter auxiliar para Budget
  int? getBudget() {
    if (currentUser == null) return null;
    if (currentUser!.preferences.containsKey("budget")) {
      final val = currentUser!.preferences["budget"];
      if (val is int) return val;
      if (val is double) return val.toInt();
    }
    return null;
  }
}
