import 'dart:collection';
import 'package:moviles/models/review.dart';

class ReviewCache {
  final int capacity;
  final _cache = LinkedHashMap<String, Review>();

  ReviewCache({this.capacity = 20});

  Review? get(String key) {
    final review = _cache.remove(key);
    if (review != null) {
      _cache[key] = review;
    }
    return review;
  }

  void put(String key, Review review) {
    if (_cache.length >= capacity) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = review;
  }

  void clear() => _cache.clear();

  int get size => _cache.length;
}
