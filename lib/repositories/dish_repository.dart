// lib/repositories/dish_repository.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:moviles/models/dish.dart';

class DishRepository {
  final CollectionReference dishesCollection =
      FirebaseFirestore.instance.collection('Dishes');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Subir imagen a Firebase Storage y obtener URL
  Future<String> _uploadImage(File image, String dishId) async {
    final ref = _storage.ref().child("dishes/$dishId.jpg");
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  /// Agregar un nuevo plato
  Future<void> addDish(String restaurantId, Dish dish, {File? image}) async {
    final docRef = dishesCollection.doc(); // genera ID
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
  }

  /// Actualizar un plato existente
  Future<void> updateDish(String restaurantId, Dish dish, {File? image}) async {
    String imageUrl = dish.imageUrl;

    if (image != null) {
      imageUrl = await _uploadImage(image, dish.id);
    }

    final updatedDish = dish.copyWith(
      restaurantId: restaurantId,
      imageUrl: imageUrl,
    );

    await dishesCollection.doc(dish.id).update(updatedDish.toMap());
  }

  /// Eliminar un plato por id
  Future<void> deleteDish(String dishId) async {
    await dishesCollection.doc(dishId).delete();
  }

  /// Obtener los platos de un restaurante
  Stream<List<Dish>> getDishesByRestaurant(String restaurantId) {
    return dishesCollection
        .where('restaurantId', isEqualTo: restaurantId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Dish.fromDocument(doc)).toList());
  }
}
