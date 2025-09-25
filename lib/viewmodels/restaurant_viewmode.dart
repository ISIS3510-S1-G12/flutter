import '../../models/restaurant.dart';
import '../../repositories/restaurant_repository.dart';

class RestaurantViewModel {
  final RestaurantRepository _repo = RestaurantRepository();

  Future<List<Restaurant>> fetchRestaurants() async {
    return await _repo.getRestaurants();
  }
}
