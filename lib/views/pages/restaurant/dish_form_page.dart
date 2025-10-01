// lib/views/pages/dish/dish_form_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moviles/models/dish.dart';
import 'package:moviles/viewmodels/dish_form_viewmodel.dart';

class DishFormPage extends StatelessWidget {
  final String restaurantId;
  final Dish? dish;

  const DishFormPage({super.key, required this.restaurantId, this.dish});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DishFormViewModel(restaurantId: restaurantId, dish: dish),
      child: Consumer<DishFormViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(vm.dish != null ? "Edit Dish" : "New Dish"),
              backgroundColor: const Color.fromARGB(255, 39, 111, 121),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: vm.formKey,
                child: ListView(
                  children: [
                    // Nombre
                    TextFormField(
                      initialValue: vm.name,
                      decoration: const InputDecoration(labelText: "Dish Name"),
                      validator: (value) =>
                          value == null || value.isEmpty ? "Enter a name" : null,
                      onSaved: (value) => vm.name = value!,
                    ),

                    // Precio
                    TextFormField(
                      initialValue: vm.price != 0.0 ? vm.price.toString() : '',
                      decoration: const InputDecoration(labelText: "Price"),
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null ||
                              double.tryParse(value) == null
                          ? "Enter a valid price"
                          : null,
                      onSaved: (value) => vm.price = double.parse(value!),
                    ),

                    // Rating
                    TextFormField(
                      initialValue: vm.rating != 0 ? vm.rating.toString() : '',
                      decoration:
                          const InputDecoration(labelText: "Rating (1-5)"),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final n = int.tryParse(value ?? '');
                        if (n == null || n < 1 || n > 5) return "Enter 1-5";
                        return null;
                      },
                      onSaved: (value) => vm.rating = int.parse(value!),
                    ),

                    // Descripción
                    TextFormField(
                      initialValue: vm.description,
                      decoration:
                          const InputDecoration(labelText: "Description"),
                      onSaved: (value) => vm.description = value ?? '',
                    ),

                    // Dish Type
                    DropdownButtonFormField<String>(
                      initialValue: vm.dishType,
                      decoration: const InputDecoration(labelText: "Dish Type"),
                      items: const [
                        DropdownMenuItem(value: "main", child: Text("Main")),
                        DropdownMenuItem(value: "drink", child: Text("Drink")),
                        DropdownMenuItem(
                            value: "dessert", child: Text("Dessert")),
                      ],
                      onChanged: vm.updateDishType,
                    ),

                    // Tags
                    TextFormField(
                      initialValue: vm.dishesTags.join(", "),
                      decoration: const InputDecoration(
                          labelText: "Tags (comma separated)"),
                      onSaved: (value) => vm.dishesTags = value!
                          .split(',')
                          .map((tag) => tag.trim())
                          .where((tag) => tag.isNotEmpty)
                          .toList(),
                    ),

                    const SizedBox(height: 16),

                    // Imagen
                    TextFormField(
                      initialValue: vm.imageUrl,
                      decoration: const InputDecoration(
                        labelText: "Image URL",
                        hintText: "Enter full image URL",
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? "Enter an image URL"
                          : null,
                      onSaved: (value) => vm.imageUrl = value!,
                      onChanged: vm.updateImageUrl,
                    ),

                    const SizedBox(height: 16),

                    vm.imageUrl.isNotEmpty
                        ? Image.network(
                            vm.imageUrl,
                            height: 150,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                              child: Icon(Icons.image_not_supported, size: 64),
                            ),
                          )
                        : const SizedBox(
                            height: 150,
                            child: Center(child: Text("No image URL provided")),
                          ),

                    const SizedBox(height: 16),

                    ElevatedButton(
                      child: const Text("Save"),
                      onPressed: () => vm.save(context),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
