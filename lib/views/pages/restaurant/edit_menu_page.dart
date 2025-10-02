// lib/views/pages/dish/edit_menu_page.dart
import 'package:flutter/material.dart';
import 'package:moviles/models/dish.dart';
import 'package:moviles/repositories/dish_repository.dart';
import 'package:moviles/views/pages/restaurant/dish_form_page.dart';


class EditMenuPage extends StatelessWidget {
  final String restaurantId;

  const EditMenuPage({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    final repository = DishRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Menu"),
        backgroundColor: const Color.fromARGB(255, 39, 111, 121),
      ),
      body: StreamBuilder<List<Dish>>(
        stream: repository.getDishesByRestaurant(restaurantId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("Error loading dishes: ${snapshot.error}"),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No dishes yet."));
          }

          final dishes = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dishes.length,
            itemBuilder: (context, index) {
              final dish = dishes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: dish.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            dish.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.image_not_supported,
                                  size: 50);
                            },
                          ),
                        )
                      : const Icon(Icons.image_not_supported, size: 50),
                  title: Text(dish.name),
                  subtitle: Text(
                    "\$${dish.price.toStringAsFixed(2)} • Rating: ${dish.rating}",
                  ),
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
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Delete Dish"),
                              content: Text(
                                  "Are you sure you want to delete '${dish.name}'?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text(
                                    "Delete",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await repository.deleteDish(dish.id);
                          }
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
        backgroundColor: const Color.fromARGB(255, 39, 111, 121),
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
