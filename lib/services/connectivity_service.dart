import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService extends ChangeNotifier {
  bool _hasConnection = true;
  bool get hasConnection => _hasConnection;

  bool _dialogShown = false;
  bool get dialogShown => _dialogShown;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityService() {
    _initConnectivity();
  }

  void _initConnectivity() {
    // Estado inicial
    Connectivity().checkConnectivity().then((result) {
      final connected = result != ConnectivityResult.none;
      _hasConnection = connected;
      notifyListeners();
    });

    // Escuchar cambios
    _subscription =
        Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      final connected = result != ConnectivityResult.none;

      if (_hasConnection != connected) {
        _hasConnection = connected;
        notifyListeners();
      }
    });
  }

  void setDialogShown(bool shown) {
    _dialogShown = shown;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
