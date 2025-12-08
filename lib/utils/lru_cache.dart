class LruCache<K, V> {
  final int capacity;
  final Map<K, V> _cache = {};
  final List<K> _usageOrder = [];
  LruCache({this.capacity = 10});
  V? get(K key) {
    if (!_cache.containsKey(key)) return null;

    _usageOrder.remove(key);
    _usageOrder.add(key);
    return _cache[key];
  }
  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _usageOrder.remove(key);
    } else if (_cache.length >= capacity) {
      final oldestKey = _usageOrder.removeAt(0);
      _cache.remove(oldestKey);
    }
    _cache[key] = value;
    _usageOrder.add(key);
  }
  bool contains(K key) => _cache.containsKey(key);
  void clear() {
    _cache.clear();
    _usageOrder.clear();
  }
  int get length => _cache.length;
  bool get isEmpty => _cache.isEmpty;
  bool get isNotEmpty => _cache.isNotEmpty;
}
