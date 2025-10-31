class LruCache<K, V> {
  final int capacity;
  final Map<K, V> _cache = {};
  final List<K> _usageOrder = [];

  LruCache({this.capacity = 10}); // capacidad por defecto

  V? get(K key) {
    if (!_cache.containsKey(key)) return null;

    // Mover al final (más recientemente usado)
    _usageOrder.remove(key);
    _usageOrder.add(key);
    return _cache[key];
  }

  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      // Si ya existe, solo actualizar orden
      _usageOrder.remove(key);
    } else if (_cache.length >= capacity) {
      // Remover el menos usado
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
}
