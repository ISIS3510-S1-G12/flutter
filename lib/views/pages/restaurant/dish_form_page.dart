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
                      value: vm.dishType,
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

                    // Imagen desde galería o URL
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => vm.pickImage(),
                          icon: const Icon(Icons.image),
                          label: const Text("Pick Image"),
                        ),
                        const SizedBox(width: 10),
                        if (vm.imageFile != null)
                          Expanded(
                            child: Image.file(
                              vm.imageFile!,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          )
                        else if (vm.imageUrl.isNotEmpty)
                          Expanded(
                            child: Image.network(
                              vm.imageUrl,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image_not_supported, size: 64),
                            ),
                          )
                        else
                          const Text("No image selected"),
                      ],
                    ),

                    const SizedBox(height: 20),

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
