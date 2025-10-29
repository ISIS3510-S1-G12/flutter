import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../models/restaurant.dart';
import '../../repositories/restaurant_repository.dart';

class UserHomeViewModel extends ChangeNotifier {
  final RestaurantRepository _restaurantRepo;

  List<Restaurant> restaurants = [];
  bool isLoading = false;
  String? errorMessage;

  UserHomeViewModel(this._restaurantRepo);

  /// --- Carga desde cache primero ---
  Future<void> loadRestaurants() async {
    isLoading = true;
    notifyListeners();

    try {
      // 1️⃣ Leer desde caché local
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_restaurants');

      if (cachedData != null) {
        final decoded = json.decode(cachedData) as List;
        restaurants = decoded.map((r) => Restaurant.fromMap(r)).toList();
        notifyListeners(); // Se muestran los datos cacheados de inmediato
      }

      // 2️⃣ Verificar conexión
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity != ConnectivityResult.none;

      if (isOnline) {
        // 3️⃣ Obtener desde red y actualizar caché
        final onlineRestaurants = await _restaurantRepo.getRestaurants();
        restaurants = onlineRestaurants;

        await prefs.setString(
          'cached_restaurants',
          json.encode(onlineRestaurants.map((r) => r.toMap()).toList()),
        );
      } else {
        errorMessage = "Mostrando datos sin conexión";
      }
    } catch (e) {
      errorMessage = "Error cargando restaurantes: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
