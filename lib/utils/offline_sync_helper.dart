import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ViewModel-like helper que gestiona datos offline (favorites y visits)
/// y sincroniza automáticamente con Firestore cuando hay conexión.
class OfflineSyncHelper extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  OfflineSyncHelper() {
    _initConnectivity();
  }

  /// Escucha cambios en la conectividad y sincroniza cuando vuelve la conexión
  void _initConnectivity() {
    Connectivity().onConnectivityChanged.listen((_) async {
      final prevOnline = _isOnline;
      _isOnline = await _hasInternetConnection();
      notifyListeners();

      if (!prevOnline && _isOnline) {
        await syncAll();
      }
    });
  }

  /// Comprueba si realmente hay internet (no solo red activa)
  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // FAVORITES OFFLINE
  // ---------------------------------------------------------------------------

  /// Guarda un favorito localmente cuando no hay internet
  Future<void> saveFavoriteOffline(String restaurantId) async {
    final box = await Hive.openBox('favorites_offline');
    await box.put(restaurantId, true);
    print("📦 Favorito guardado offline: $restaurantId");
  }

  /// Sincroniza favoritos pendientes con Firestore
  Future<void> syncFavorites() async {
    final box = await Hive.openBox('favorites_offline');
    if (box.isEmpty) return;

    print("🔄 Sincronizando ${box.length} favoritos pendientes...");

    final List keys = List.from(box.keys);
    for (final id in keys) {
      try {
        await _firestore.collection('Favorites').doc(id).set({'isFavorite': true});
        await box.delete(id);
        print("Favorito sincronizado: $id");
      } catch (e) {
        print("Error al sincronizar favorito $id: $e");
      }
    }
  }

  // ---------------------------------------------------------------------------
  // VISITS OFFLINE
  // ---------------------------------------------------------------------------

  /// Guarda una visita localmente cuando no hay internet
  Future<void> saveVisitOffline(String restaurantId) async {
    final box = await Hive.openBox('visits_offline');
    await box.put(restaurantId, DateTime.now().toIso8601String());
    print("📦 Visita guardada offline: $restaurantId");
  }

  /// Sincroniza visitas pendientes con Firestore
  Future<void> syncVisits() async {
    final box = await Hive.openBox('visits_offline');
    if (box.isEmpty) return;

    print("🔄 Sincronizando ${box.length} visitas pendientes...");

    final List keys = List.from(box.keys);
    for (final id in keys) {
      try {
        await _firestore.collection('Visits').add({
          'restaurantId': id,
          'timestamp': box.get(id),
        });
        await box.delete(id);
        print(" Visita sincronizada: $id");
      } catch (e) {
        print("⚠️ Error al sincronizar visita $id: $e");
      }
    }
  }

  // ---------------------------------------------------------------------------
  // SINCRONIZACIÓN GLOBAL
  // ---------------------------------------------------------------------------

  /// Llama a ambos procesos de sincronización
  Future<void> syncAll() async {
    if (!_isOnline) return;

    print("Conexión restaurada, sincronizando datos pendientes...");
    await syncFavorites();
    await syncVisits();
  }

  // ---------------------------------------------------------------------------
  // UTILIDADES DE UI
  // ---------------------------------------------------------------------------

  /// Muestra un banner de “No connection: data stored locally.”
  void showOfflineBanner(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("⚠️ No connection: data stored locally."),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Muestra un banner de “Connection restored: data synced.”
  void showSyncedBanner(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(" Connection restored: pending data synced."),
        backgroundColor: Colors.green,
      ),
    );
  }
}
