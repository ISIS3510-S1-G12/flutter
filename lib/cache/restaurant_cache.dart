import '../models/restaurant.dart';
import '../utils/lru_cache.dart'; // o donde tengas tu clase LruCache

class RestaurantCache {
  static final LruCache<String, Restaurant> _cache = LruCache(capacity: 20);

  static Restaurant? get(String id) => _cache.get(id);

  static void put(String id, Restaurant restaurant) => _cache.put(id, restaurant);

  static bool contains(String id) => _cache.contains(id);

  static void clear() => _cache.clear();
}
