import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:moviles/models/dish.dart';

class DishRepository {
  final CollectionReference dishesCollection =
      FirebaseFirestore.instance.collection('Dishes');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final _localDishesController = StreamController<List<Dish>>.broadcast();
  Stream<List<Dish>> get localDishesStream => _localDishesController.stream;

  /// Archivo local donde se guardan los platos offline
  Future<File> _getLocalFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/local_dishes.json');
  }

  /// Verifica si hay conexión real a internet
  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();

    // Si no hay ningún tipo de red
    if (result == ConnectivityResult.none) {
      print(">>> Sin conexión de red detectada (ConnectivityResult.none)");
      return false;
    }

    // Comprobamos si hay acceso real a Internet
    try {
      final lookup = await InternetAddress.lookup('google.com');
      final hasConnection = lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
      print(">>> Verificación de conexión real: $hasConnection");
      return hasConnection;
    } catch (e) {
      print(">>> Error verificando conexión a Internet: $e");
      return false;
    }
  }

  Future<void> _notifyLocalChanges() async {
    final localDishes = await getLocalDishes();
    _localDishesController.add(localDishes);
  }

  /// 💾 Guarda un plato localmente cuando no hay conexión
  Future<void> _saveDishLocally(Dish dish) async {
    final file = await _getLocalFile();
    List<Map<String, dynamic>> dishes = [];

    if (await file.exists()) {
      final content = await file.readAsString();
      if (content.isNotEmpty) {
        dishes = List<Map<String, dynamic>>.from(jsonDecode(content));
      }
    }

    dishes.add(dish.toMap());
    await file.writeAsString(jsonEncode(dishes));
    print(" Plato guardado localmente (sin conexión): ${dish.name}");
    await _notifyLocalChanges();
  }

  Future<List<Dish>> getLocalDishes() async {
    final file = await _getLocalFile();
    if (await file.exists()) {
      final content = await file.readAsString();
      if (content.isNotEmpty) {
        final List data = jsonDecode(content);
        return data.map((e) => Dish.fromJson(e)).toList();
      }
    }
    return [];
  }

  Future<void> clearLocalDishes() async {
    final file = await _getLocalFile();
    if (await file.exists()) await file.delete();
  }

  Future<String> _uploadImage(File image, String dishId) async {
    final ref = _storage.ref().child("dishes/$dishId.jpg");
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  /// ➕ Agregar plato (online u offline)
  Future<void> addDish(String restaurantId, Dish dish, {File? image}) async {
    final online = await _isOnline();
    print(">>> Entrando a addDish() con online=$online");

    if (online) {
      print(">>> Guardando plato en Firebase...");
      final docRef = dishesCollection.doc();
      String imageUrl = dish.imageUrl;

      if (image != null) {
        imageUrl = await _uploadImage(image, docRef.id);
      }

      final newDish = dish.copyWith(
        id: docRef.id,
        restaurantId: restaurantId,
        imageUrl: imageUrl,
      );

      await docRef.set(newDish.toMap());
      print(" Plato guardado en Firestore: ${dish.name}");
    } else {
      print(">>> Guardando plato localmente...");
      await _saveDishLocally(
        dish.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          restaurantId: restaurantId,
        ),
      );
    }
  }

  /// ✏️ Actualizar plato (online u offline)
  Future<void> updateDish(String restaurantId, Dish dish, {File? image}) async {
    final online = await _isOnline();
    print(">>> Entrando a updateDish() con online=$online");

    if (online) {
      print(">>> Actualizando plato en Firebase...");
      String imageUrl = dish.imageUrl;
      if (image != null) {
        imageUrl = await _uploadImage(image, dish.id);
      }

      final updatedDish = dish.copyWith(
        restaurantId: restaurantId,
        imageUrl: imageUrl,
      );

      await dishesCollection.doc(dish.id).update(updatedDish.toMap());
      print(" Plato actualizado en Firestore: ${dish.name}");
    } else {
      print(">>> Actualizando plato localmente...");
      final localDishes = await getLocalDishes();
      final updatedList = localDishes.map((d) {
        if (d.id == dish.id) return dish;
        return d;
      }).toList();

      final file = await _getLocalFile();
      await file.writeAsString(jsonEncode(updatedList.map((e) => e.toMap()).toList()));
      print(" Plato actualizado localmente (sin conexión): ${dish.name}");
      await _notifyLocalChanges();
    }
  }

  /// ❌ Eliminar plato (online u offline)
  Future<void> deleteDish(String dishId) async {
    final online = await _isOnline();
    print(">>> Entrando a deleteDish() con online=$online");

    if (online) {
      await dishesCollection.doc(dishId).delete();
      print(" Plato eliminado de Firestore: $dishId");
    } else {
      final localDishes = await getLocalDishes();
      final updatedList = localDishes.where((d) => d.id != dishId).toList();

      final file = await _getLocalFile();
      await file.writeAsString(jsonEncode(updatedList.map((e) => e.toMap()).toList()));
      print(" Plato eliminado localmente (sin conexión): $dishId");
      await _notifyLocalChanges();
    }
  }

  /// 📡 Obtener platos por restaurante
  Stream<List<Dish>> getDishesByRestaurant(String restaurantId) async* {
    final online = await _isOnline();
    print(">>> getDishesByRestaurant() online=$online");

    if (online) {
      yield* dishesCollection
          .where('restaurantId', isEqualTo: restaurantId)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => Dish.fromDocument(doc)).toList());
    } else {
      await _notifyLocalChanges();
      yield* localDishesStream.map(
        (list) => list.where((d) => d.restaurantId == restaurantId).toList(),
      );
    }
  }

  /// 🔄 Sincronizar platos guardados localmente cuando vuelve la conexión
  Future<void> syncLocalDishes() async {
    final online = await _isOnline();
    if (!online) {
      print(">>> No se puede sincronizar: sin conexión real a Internet.");
      return;
    }

    final localDishes = await getLocalDishes();
    for (final dish in localDishes) {
      final docRef = dishesCollection.doc();
      await docRef.set(dish.copyWith(id: docRef.id).toMap());
      print(" Plato sincronizado con Firestore: ${dish.name}");
    }

    await clearLocalDishes();
    await _notifyLocalChanges();
  }

  void dispose() {
    _localDishesController.close();
  }
}
