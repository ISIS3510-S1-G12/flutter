// lib/viewmodels/user_viewmodel.dart
import 'package:flutter/material.dart';
import '../repositories/user_repository.dart';

class UserViewModel extends ChangeNotifier {
  final UserRepository _repo;
  UserViewModel(this._repo);

  Map<String, dynamic>? _userData;
  bool _loading = false;
  String? _error;

  Map<String, dynamic>? get userData => _userData;
  bool get loading => _loading;
  String? get error => _error;

  // Obtener datos de usuario
  Future<void> fetchUser(String uid) async {
    _loading = true;
    notifyListeners();
    try {
      _userData = await _repo.getUserData(uid);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  // Actualizar perfil
  Future<void> updateUser(
    String uid, {
    String? name,
    String? profilePicture,
    Map<String, dynamic>? preferences,
    List<String>? favoriteRestaurants,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      await _repo.updateUserProfile(
        uid,
        name: name,
        profilePicture: profilePicture,
        preferences: preferences,
        favoriteRestaurants: favoriteRestaurants,
      );
      await fetchUser(uid); // refrescar datos después de actualizar
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }
}
