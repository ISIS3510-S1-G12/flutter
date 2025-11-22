// lib/viewmodels/dish_form_viewmodel.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moviles/models/dish.dart';
import 'package:moviles/repositories/dish_repository.dart';

class DishFormViewModel extends ChangeNotifier {
  final String restaurantId;
  final Dish? dish;
  final formKey = GlobalKey<FormState>();

  final DishRepository _repository = DishRepository(); // singleton

  // Campos editables
  String name = '';
  double price = 0.0;
  int rating = 0;
  String description = '';
  String dishType = 'main';
  List<String> dishesTags = [];
  String imageUrl = '';
  File? imageFile;

  DishFormViewModel({required this.restaurantId, this.dish}) {
    if (dish != null) {
      name = dish!.name;
      price = dish!.price;
      rating = dish!.rating;
      description = dish!.description;
      dishType = dish!.dishType;
      dishesTags = dish!.dishesTags;
      imageUrl = dish!.imageUrl;
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      imageFile = File(pickedFile.path);
      notifyListeners();
    }
  }

  void updateDishType(String? newType) {
    if (newType != null) {
      dishType = newType;
      notifyListeners();
    }
  }

  void updateImageUrl(String value) {
    imageUrl = value;
    notifyListeners();
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
      description: description,
      dishType: dishType,
      dishesTags: dishesTags,
      imageUrl: imageUrl,
    );

    try {
      if (dish == null) {
        await _repository.addDish(restaurantId, newDish, image: imageFile);
      } else {
        await _repository.updateDish(restaurantId, newDish, image: imageFile);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("The dish was saved")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving dish: $e")),
      );
    }
  }
}
