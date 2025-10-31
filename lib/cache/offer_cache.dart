// lib/data/offer_cache.dart
import '../models/offer.dart';
import '../utils/lru_cache.dart';

class OfferCache {
  static final OfferCache _instance = OfferCache._internal();
  factory OfferCache() => _instance;
  OfferCache._internal();

  final LruCache<String, Offer> _cache = LruCache(capacity: 20);

  Offer? get(String id) => _cache.get(id);
  void put(String id, Offer offer) => _cache.put(id, offer);
  bool contains(String id) => _cache.contains(id);
  void clear() => _cache.clear();
}