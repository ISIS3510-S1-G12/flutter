// lib/viewmodels/auth_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repo;
  AuthViewModel(this._repo) {
    _initConnectivity();
  }

  bool _loading = false;
  String? _error;
  bool _isOnline = true;

  bool get loading => _loading;
  String? get error => _error;
  bool get isOnline => _isOnline;

  // Inicializar listener de conectividad
  void _initConnectivity() {
    Connectivity().onConnectivityChanged.listen((_) async {
      _isOnline = await InternetConnectionChecker().hasConnection;
      notifyListeners();
    });
  }

  // Registrar usuario
  Future<void> register(String who, String name, String email, String password) async {
    if (!_isOnline) {
      _error = "No internet connection. Try again later.";
      notifyListeners();
      return;
    }

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

  // Registrar usuario y retornar UID
  Future<String> registerAndGetUid(String who, String name, String email, String password) async {
    if (!_isOnline) {
      _error = "No internet connection. Try again later.";
      notifyListeners();
      throw Exception(_error);
    }

    _loading = true;
    notifyListeners();
    try {
      final uid = await _repo.register(
        who: who,
        name: name,
        email: email,
        password: password,
      );
      _error = null;
      return uid;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Login
  Future<void> login(String who, String email, String password) async {
    if (!_isOnline) {
      _error = "No internet connection. Try again later.";
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();
    try {
      await _repo.login(
        email: email,
        password: password,
        expectedRole: who,
      );
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
