import 'package:flutter/material.dart';
import 'package:moviles/models/dish.dart';
import 'package:moviles/repositories/dish_repository.dart';

import 'dish_form_page.dart';

class EditMenuPage extends StatelessWidget {
  final String restaurantId;

  const EditMenuPage({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    final repository = DishRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Menu"),
      ),
      body: StreamBuilder<List<Dish>>(
        stream: repository.getDishesByRestaurant(restaurantId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final dishes = snapshot.data!;
          if (dishes.isEmpty) return const Center(child: Text("No dishes yet."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dishes.length,
            itemBuilder: (context, index) {
              final dish = dishes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: dish.imageUrl.isNotEmpty
                      ? Image.network(
                          dish.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.image_not_supported, size: 50);
                          },
                        )
                      : const Icon(Icons.image_not_supported, size: 50),
                  title: Text(dish.name),
                  subtitle: Text("\$${dish.price.toStringAsFixed(2)} - Rating: ${dish.rating}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DishFormPage(
                                restaurantId: restaurantId,
                                dish: dish,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await repository.deleteDish(dish.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DishFormPage(restaurantId: restaurantId),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
