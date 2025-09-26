import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moviles/models/dish.dart';


class DishRepository {
  final CollectionReference dishesCollection =
      FirebaseFirestore.instance.collection('Dishes');

  Future<void> addDish(Dish dish) async {
    await dishesCollection.add(dish.toMap());
  }

  Future<void> updateDish(Dish dish) async {
    await dishesCollection.doc(dish.id).update(dish.toMap());
  }

  Future<void> deleteDish(String dishId) async {
    await dishesCollection.doc(dishId).delete();
  }

  Stream<List<Dish>> getDishesByRestaurant(String restaurantId) {
    return dishesCollection
        .where('restaurantId', isEqualTo: restaurantId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Dish.fromDocument(doc)).toList());
  }
}
