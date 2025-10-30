import 'package:hive/hive.dart';
import 'package:moviles/models/review.dart';

class HiveReviewCache {
  final Box _box = Hive.box('review_cache');

  Future<void> cacheReviews(String restaurantId, List<Review> reviews) async {
    final data = reviews.map((r) => r.toJson()).toList();
    await _box.put(restaurantId, data);
  }

  Future<List<Review>> getCachedReviews(String restaurantId) async {
    final data = _box.get(restaurantId);
    if (data == null) return [];
    return (data as List).map((json) => Review.fromJson(Map<String, dynamic>.from(json))).toList();
  }
}
