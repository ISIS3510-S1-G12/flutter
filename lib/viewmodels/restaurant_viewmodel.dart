import 'package:flutter/foundation.dart';
import '../../models/restaurant.dart';
import '../../repositories/restaurant_repository.dart';

class RestaurantViewModel extends ChangeNotifier {
  final RestaurantRepository _repo = RestaurantRepository();

  List<Restaurant> restaurants = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchRestaurants() async {
    try {
      isLoading = true;
      notifyListeners();

      restaurants = await _repo.getRestaurants();

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 🔹 Nuevo método
  Future<void> addRestaurant(Restaurant restaurant) async {
    try {
      await _repo.addRestaurant(restaurant);
      // refrescar lista después de guardar
      await fetchRestaurants();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }
}
