import 'package:flutter/material.dart';
import 'package:moviles/models/dish.dart';
import 'package:moviles/repositories/dish_repository.dart';

class DishFormPage extends StatefulWidget {
  final String restaurantId;
  final Dish? dish; // null = crear nuevo, no null = editar

  const DishFormPage({super.key, required this.restaurantId, this.dish});

  @override
  State<DishFormPage> createState() => _DishFormPageState();
}

class _DishFormPageState extends State<DishFormPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  double _price = 0.0;
  int _rating = 0;
  String _imageUrl = '';
  String _description = '';
  String _dishType = 'main'; // valor default
  List<String> _dishesTags = [];

  final DishRepository repository = DishRepository();

  @override
  void initState() {
    super.initState();
    if (widget.dish != null) {
      _name = widget.dish!.name;
      _price = widget.dish!.price;
      _rating = widget.dish!.rating;
      _imageUrl = widget.dish!.imageUrl;
      _description = widget.dish!.description;
      _dishType = widget.dish!.dishType;
      _dishesTags = widget.dish!.dishesTags;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.dish != null ? "Edit Dish" : "New Dish")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Nombre
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: "Dish Name"),
                validator: (value) => value == null || value.isEmpty ? "Enter a name" : null,
                onSaved: (value) => _name = value!,
              ),

              // Precio
              TextFormField(
                initialValue: _price != 0.0 ? _price.toString() : '',
                decoration: const InputDecoration(labelText: "Price"),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || double.tryParse(value) == null ? "Enter a valid price" : null,
                onSaved: (value) => _price = double.parse(value!),
              ),

              // Rating
              TextFormField(
                initialValue: _rating != 0 ? _rating.toString() : '',
                decoration: const InputDecoration(labelText: "Rating (1-5)"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final n = int.tryParse(value ?? '');
                  if (n == null || n < 1 || n > 5) return "Enter 1-5";
                  return null;
                },
                onSaved: (value) => _rating = int.parse(value!),
              ),

              // Descripción
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(labelText: "Description"),
                onSaved: (value) => _description = value ?? '',
              ),

              // Dish Type
              DropdownButtonFormField<String>(
                value: _dishType,
                decoration: const InputDecoration(labelText: "Dish Type"),
                items: const [
                  DropdownMenuItem(value: "main", child: Text("Main")),
                  DropdownMenuItem(value: "drink", child: Text("Drink")),
                  DropdownMenuItem(value: "dessert", child: Text("Dessert")),
                ],
                onChanged: (value) => setState(() => _dishType = value ?? 'main'),
              ),

              // Tags (separados por coma)
              TextFormField(
                initialValue: _dishesTags.join(", "),
                decoration: const InputDecoration(labelText: "Tags (comma separated)"),
                onSaved: (value) => _dishesTags = value!
                    .split(',')
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .toList(),
              ),

              const SizedBox(height: 16),

              // Imagen
              TextFormField(
                initialValue: _imageUrl,
                decoration: const InputDecoration(
                  labelText: "Image URL",
                  hintText: "Enter full image URL",
                ),
                validator: (value) => value == null || value.isEmpty ? "Enter an image URL" : null,
                onSaved: (value) => _imageUrl = value!,
              ),

              const SizedBox(height: 16),

              _imageUrl.isNotEmpty
                  ? Image.network(
                      _imageUrl,
                      height: 150,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.image_not_supported, size: 64),
                      ),
                    )
                  : const SizedBox(
                      height: 150,
                      child: Center(child: Text("No image URL provided")),
                    ),

              const SizedBox(height: 16),

              // Botón Guardar
              ElevatedButton(
                child: const Text("Save"),
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  _formKey.currentState!.save();

                  final dish = Dish(
                    id: widget.dish?.id ?? '',
                    restaurantId: widget.restaurantId,
                    name: _name,
                    price: _price,
                    rating: _rating,
                    imageUrl: _imageUrl,
                    description: _description,
                    dishType: _dishType,
                    dishesTags: _dishesTags,
                  );

                  if (widget.dish != null) {
                    await repository.updateDish(dish);
                  } else {
                    await repository.addDish(dish);
                  }

                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
