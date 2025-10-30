import 'dart:collection';

/// Implementación genérica de una LRU Cache.
class LruCache<K, V> {
  final int maxSize;
  final _cache = LinkedHashMap<K, V>();

  LruCache(this.maxSize);

  /// Obtiene un valor y lo marca como usado recientemente.
  V? get(K key) {
    final value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value; // Mover al final → más recientemente usado
    }
    return value;
  }

  /// Inserta un nuevo valor, eliminando el más viejo si supera el tamaño.
  void put(K key, V value) {
    if (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first); // Eliminar el menos usado
    }
    _cache[key] = value;
  }

  /// Limpia toda la caché.
  void clear() => _cache.clear();

  /// Devuelve todos los valores actuales.
  List<V> get values => _cache.values.toList();
}
