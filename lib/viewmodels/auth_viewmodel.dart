// lib/viewmodels/auth_viewmodel.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';

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

  /// Inicializa el listener de conectividad
  void _initConnectivity() {
    Connectivity().onConnectivityChanged.listen((_) async {
      final prevOnline = _isOnline;
      _isOnline = await _hasInternetConnection();
      notifyListeners();

      // Si antes estaba offline y ahora volvió la conexión, sincronizar
      if (!prevOnline && _isOnline) {
        await syncPendingRegistrations();
        await syncPendingLogins(); // 🔹 Nuevo
      }
    });
  }

  /// Verifica conexión a internet real
  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Registrar usuario normalmente (solo online)
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

  /// Registrar usuario y devolver UID (solo online)
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

  /// Guardar registro pendiente cuando no hay conexión
  Future<void> savePendingRegistration({
    required String who,
    required String name,
    required String email,
    required String password,
  }) async {
    final box = await Hive.openBox('pendingRegistrations');
    await box.add({
      'who': who,
      'name': name,
      'email': email,
      'password': password,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Sincronizar los registros pendientes cuando haya conexión
  Future<void> syncPendingRegistrations() async {
    if (!_isOnline) return;

    final box = await Hive.openBox('pendingRegistrations');
    if (box.isEmpty) return;

    print("🔄 Intentando sincronizar ${box.length} registros pendientes...");

    final List<dynamic> pending = List.from(box.values);

    for (int i = 0; i < pending.length; i++) {
      final data = pending[i];
      try {
        await _repo.register(
          who: data['who'],
          name: data['name'],
          email: data['email'],
          password: data['password'],
        );
        print(" Registro sincronizado: ${data['email']}");
        await box.deleteAt(i);
      } catch (e) {
        print("⚠️ Error al sincronizar ${data['email']}: $e");
      }
    }
  }

  /// Guardar login pendiente cuando no hay conexión 🔹 NUEVO
  Future<void> savePendingLogin({
    required String who,
    required String email,
    required String password,
  }) async {
    final box = await Hive.openBox('pendingLogins');
    await box.add({
      'who': who,
      'email': email,
      'password': password,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Sincronizar logins pendientes cuando vuelva la conexión 🔹 NUEVO
  Future<void> syncPendingLogins() async {
    if (!_isOnline) return;

    final box = await Hive.openBox('pendingLogins');
    if (box.isEmpty) return;

    print("🔄 Intentando sincronizar ${box.length} logins pendientes...");

    final List<dynamic> pending = List.from(box.values);

    for (int i = 0; i < pending.length; i++) {
      final data = pending[i];
      try {
        await _repo.login(
          email: data['email'],
          password: data['password'],
          expectedRole: data['who'],
        );
        print("✅ Login sincronizado: ${data['email']}");
        await box.deleteAt(i);
      } catch (e) {
        print("⚠️ Error al sincronizar login ${data['email']}: $e");
      }
    }
  }

  /// Login
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

  /// Logout
  Future<void> logout() async {
    await _repo.logout();
  }
}
