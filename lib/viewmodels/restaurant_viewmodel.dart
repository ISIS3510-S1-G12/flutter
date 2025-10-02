import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/restaurant.dart';
import '../../repositories/restaurant_repository.dart';

/// 🔹 Interfaz para filtros
abstract class RestaurantFilter {
  List<Restaurant> apply(List<Restaurant> restaurants);
}

/// 🔹 Filtro por tipo de comida
class FilterByType implements RestaurantFilter {
  final String query;
  FilterByType(this.query);

  @override
  List<Restaurant> apply(List<Restaurant> restaurants) {
    return restaurants
        .where((r) => r.typeOfFood.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}

/// 🔹 Filtro: solo restaurantes con oferta
class FilterWithOffer implements RestaurantFilter {
  @override
  List<Restaurant> apply(List<Restaurant> restaurants) {
    return restaurants.where((r) => r.offer).toList();
  }
}

/// 🔹 Filtro: solo restaurantes sin oferta
class FilterWithoutOffer implements RestaurantFilter {
  @override
  List<Restaurant> apply(List<Restaurant> restaurants) {
    return restaurants.where((r) => !r.offer).toList();
  }
}

/// 🔹 ViewModel principal
class RestaurantViewModel extends ChangeNotifier {
  final RestaurantRepository _repo;
  RestaurantViewModel(this._repo);

  List<Restaurant> restaurants = []; // todos
  List<Restaurant> filteredRestaurants = []; // filtrados
  bool isLoading = false;
  String? errorMessage;

  RestaurantFilter? _activeFilter;

  /// Cargar todos los restaurantes
  Future<void> fetchRestaurants() async {
    try {
      isLoading = true;
      notifyListeners();

      restaurants = await _repo.getRestaurants();
      filteredRestaurants = restaurants;

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Guardar un restaurante con imagen opcional
  Future<void> saveRestaurantOwner({
    required String id,
    required String name,
    required String email,
    required String address,
    required String typeOfFood,
    required bool offer,
    File? imageFile,
  }) async {
    try {
      isLoading = true;
      notifyListeners();

      String imageUrl = "";
      if (imageFile != null) {
        imageUrl = await _repo.uploadImage(id, imageFile);
      }

      final restaurant = Restaurant(
        id: id,
        name: name,
        email: email,
        address: address,
        typeOfFood: typeOfFood,
        offer: offer,
        imageUrl: imageUrl,
        openingTime: 9,
        closingTime: 22,
        busiestHours: {},
        rating: 0.0,
      );

      await _repo.saveRestaurantWithId(id, restaurant);
      await fetchRestaurants(); // refresca lista

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Aplica un filtro
  void applyFilter(RestaurantFilter filter) {
    _activeFilter = filter;
    filteredRestaurants = filter.apply(restaurants);
    notifyListeners();
  }

  /// Limpia el filtro
  void clearFilter() {
    _activeFilter = null;
    filteredRestaurants = restaurants;
    notifyListeners();
  }
}
