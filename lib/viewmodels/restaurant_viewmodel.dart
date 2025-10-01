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
  final RestaurantRepository _repo = RestaurantRepository();

  List<Restaurant> restaurants = []; // todos
  List<Restaurant> filteredRestaurants = []; // filtrados
  bool isLoading = false;
  String? errorMessage;

  RestaurantFilter? _activeFilter;

  Future<void> fetchRestaurants() async {
    try {
      isLoading = true;
      notifyListeners();

      restaurants = await _repo.getRestaurants();
      filteredRestaurants = restaurants; // por defecto sin filtro

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 🔹 Aplica un filtro
  void applyFilter(RestaurantFilter filter) {
    _activeFilter = filter;
    filteredRestaurants = filter.apply(restaurants);
    notifyListeners();
  }

  /// 🔹 Limpia el filtro
  void clearFilter() {
    _activeFilter = null;
    filteredRestaurants = restaurants;
    notifyListeners();
  }

  /// 🔹 Agregar restaurante y refrescar lista
  Future<void> addRestaurant(Restaurant restaurant) async {
    try {
      await _repo.addRestaurant(restaurant);
      await fetchRestaurants();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }
}
