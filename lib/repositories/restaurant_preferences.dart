import 'package:shared_preferences/shared_preferences.dart';

class RestaurantPreferences {
  Future<void> saveLastRestaurant(String restaurantId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_restaurant', restaurantId);
  }

  Future<String?> getLastRestaurant() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_restaurant');
  }
}
