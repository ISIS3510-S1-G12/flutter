import 'package:hive/hive.dart';
import 'package:moviles/models/restaurant.dart';

class HiveFavoritesCache {
  static const String _boxName = 'favoritesBox';
  late Box _box;

  /// Inicializa la caja Hive si no está abierta
  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox(_boxName);
    } else {
      _box = Hive.box(_boxName);
    }
  }

  /// Guarda los restaurantes favoritos en Hive
  Future<void> cacheFavorites(List<Restaurant> favorites) async {
    try {
      await init();
      final data = favorites.map((r) => r.toMap()).toList();
      await _box.put('favorites', data);
      print(" Guardados ${favorites.length} favoritos en Hive");
    } catch (e) {
      print(" Error guardando favoritos en Hive: $e");
    }
  }

  /// Obtiene los favoritos desde Hive
  Future<List<Restaurant>> getCachedFavorites() async {
    try {
      await init();
      final data = _box.get('favorites', defaultValue: []);
      if (data is List) {
        final favs = data
            .map((json) => Restaurant.fromMap(Map<String, dynamic>.from(json)))
            .toList();
        print(" Cargados ${favs.length} favoritos desde Hive");
        return favs;
      }
      return [];
    } catch (e) {
      print(" Error cargando favoritos desde Hive: $e");
      return [];
    }
  }

  /// Limpia la caché local
  Future<void> clearCache() async {
    await init();
    await _box.delete('favorites');
    print("🧹 Caché de favoritos limpiada");
  }
}
