import 'dart:io';
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


  //     UTILIDADES LOCALES


  Future<File> _getLocalFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/local_dishes.json');
  }

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

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
    print("Plato guardado localmente (sin conexión)");
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


  //         IMÁGENES


  Future<String> _uploadImage(File image, String dishId) async {
    final ref = _storage.ref().child("dishes/$dishId.jpg");
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }


  //   CREAR / EDITAR / ELIMINAR


  Future<void> addDish(String restaurantId, Dish dish, {File? image}) async {
    final online = await _isOnline();

    if (online) {
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
    } else {
      // Guardar localmente cuando no hay conexión
      await _saveDishLocally(
        dish.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(), // ID local único
          restaurantId: restaurantId,
        ),
      );
    }
  }

  Future<void> updateDish(String restaurantId, Dish dish, {File? image}) async {
    final online = await _isOnline();

    if (online) {
      String imageUrl = dish.imageUrl;
      if (image != null) {
        imageUrl = await _uploadImage(image, dish.id);
      }

      final updatedDish = dish.copyWith(
        restaurantId: restaurantId,
        imageUrl: imageUrl,
      );

      await dishesCollection.doc(dish.id).update(updatedDish.toMap());
    } else {
      // Guardar offline (reemplazar en archivo local)
      final localDishes = await getLocalDishes();
      final updatedList = localDishes.map((d) {
        if (d.id == dish.id) return dish;
        return d;
      }).toList();

      final file = await _getLocalFile();
      await file.writeAsString(jsonEncode(updatedList.map((e) => e.toMap()).toList()));
      print("Plato actualizado localmente (sin conexión)");
    }
  }

  Future<void> deleteDish(String dishId) async {
    await dishesCollection.doc(dishId).delete();
  }


  //     OBTENER PLATOS


  Stream<List<Dish>> getDishesByRestaurant(String restaurantId) async* {
    final online = await _isOnline();

    if (online) {
      yield* dishesCollection
          .where('restaurantId', isEqualTo: restaurantId)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => Dish.fromDocument(doc)).toList());
    } else {
      final localDishes = await getLocalDishes();
      yield localDishes.where((d) => d.restaurantId == restaurantId).toList();
    }
  }


  //     SINCRONIZAR LOCAL → FIRESTORE


  Future<void> syncLocalDishes() async {
    final online = await _isOnline();
    if (!online) return;

    final localDishes = await getLocalDishes();
    for (final dish in localDishes) {
      final docRef = dishesCollection.doc();
      await docRef.set(dish.copyWith(id: docRef.id).toMap());
      print("☁️ Plato sincronizado: ${dish.name}");
    }

    await clearLocalDishes();
  }
}
