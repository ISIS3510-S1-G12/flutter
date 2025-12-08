import '../utils/lru_cache.dart'; // tu LruCache genérico
class UserCache {
  static final LruCache<String, Map<String, dynamic>> _cache = LruCache(capacity: 20);
  static void put(String uid, Map<String, dynamic> data) {
    _cache.put(uid, data);
  }
  static Map<String, dynamic>? get(String uid) {
    return _cache.get(uid);
  }
  static bool contains(String uid) {
    return _cache.contains(uid);
  }
  static void clear() {
    _cache.clear();
  }
  static bool isEmpty() {
    return _cache.isEmpty;
  }
}
