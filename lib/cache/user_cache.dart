class UserCache {
  static final Map<String, Map<String, dynamic>> _pendingUpdates = {};

  /// Guarda una actualización en cache
  static void put(String uid, Map<String, dynamic> data) {
    _pendingUpdates[uid] = data;
  }

  /// Obtiene la actualización en cache para un usuario
  static Map<String, dynamic>? get(String uid) {
    return _pendingUpdates[uid];
  }

  /// Verifica si hay un update pendiente
  static bool contains(String uid) {
    return _pendingUpdates.containsKey(uid);
  }

  /// Limpia la cache completamente
  static void clear() {
    _pendingUpdates.clear();
  }

  /// Saber si hay elementos en cache
  static bool isEmpty() {
    return _pendingUpdates.isEmpty;
  }
}
