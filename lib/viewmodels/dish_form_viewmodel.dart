// lib/viewmodels/dish_form_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:moviles/models/dish.dart';
import 'package:moviles/repositories/dish_repository.dart';

class DishFormViewModel extends ChangeNotifier {
  final String restaurantId;
  final Dish? dish;

  final formKey = GlobalKey<FormState>();

  String name = '';
  double price = 0.0;
  int rating = 0;
  String imageUrl = '';
  String description = '';
  String dishType = 'main';
  List<String> dishesTags = [];

  final DishRepository repository = DishRepository();

  DishFormViewModel({required this.restaurantId, this.dish}) {
    if (dish != null) {
      name = dish!.name;
      price = dish!.price;
      rating = dish!.rating;
      imageUrl = dish!.imageUrl;
      description = dish!.description;
      dishType = dish!.dishType;
      dishesTags = dish!.dishesTags;
    }
  }

  Future<void> save(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;
    formKey.currentState!.save();

    final newDish = Dish(
      id: dish?.id ?? '',
      restaurantId: restaurantId,
      name: name,
      price: price,
      rating: rating,
      imageUrl: imageUrl,
      description: description,
      dishType: dishType,
      dishesTags: dishesTags,
    );

    if (dish != null) {
      await repository.updateDish(newDish);
    } else {
      await repository.addDish(newDish);
    }

    Navigator.pop(context);
  }

  void updateDishType(String? value) {
    dishType = value ?? 'main';
    notifyListeners();
  }

  void updateImageUrl(String value) {
    imageUrl = value;
    notifyListeners();
  }
}
