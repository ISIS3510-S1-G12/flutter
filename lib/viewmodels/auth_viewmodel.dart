// lib/viewmodels/auth_viewmodel.dart
import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repo;
  AuthViewModel(this._repo);

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  // Registrar usuario
  Future<void> register(String who,String name, String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      await _repo.register(who: who, name: name, email: email, password: password);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  // Login
  Future<void> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      await _repo.login(email: email, password: password);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  // Logout
  Future<void> logout() async {
    await _repo.logout();
  }
}
