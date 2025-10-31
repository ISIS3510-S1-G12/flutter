import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // compute()
import 'package:provider/provider.dart';
import '/viewmodels/restaurant_viewmodel.dart';
import '/models/restaurant.dart';
import '/views/pages/user/user_restaurant_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// --- Cálculo de estadísticas en segundo plano (Isolate) ---
Map<String, dynamic> calculateFavoriteStats(List<Restaurant> favorites) {
  final withOffers = favorites.where((r) => r.offer == true).toList();
  final percentage = favorites.isEmpty
      ? 0
      : ((withOffers.length / favorites.length) * 100).round();

  return {
    'totalFavorites': favorites.length,
    'favoritesWithOffers': withOffers.length,
    'percentageWithOffers': percentage,
    'todaysDiscounts': withOffers,
  };
}

class UserFavoritesPage extends StatefulWidget {
  const UserFavoritesPage({super.key});

  @override
  State<UserFavoritesPage> createState() => _UserFavoritesPageState();
}

class _UserFavoritesPageState extends State<UserFavoritesPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final vm = Provider.of<RestaurantViewModel>(context, listen: false);

      print("🐝 Intentando cargar favoritos (modo offline primero)...");
      await vm.fetchFavorites(fromCache: true); // 🔹 1. Modo offline

      print("📡 Escuchando stream de favoritos...");
      vm.listenToFavoritesStream(); // 🔹 2. Stream online

      print("🌐 Cargando favoritos desde red...");
      await vm.fetchFavorites(); // 🔹 3. Cargar desde Firestore y actualizar Hive

      if (vm.favorites.isEmpty) return;

      // 🔹 4. Calcular estadísticas con compute()
      final stats = await compute(calculateFavoriteStats, vm.favorites);
      vm.todaysDiscounts = List<Restaurant>.from(stats['todaysDiscounts']);
      final total = stats['totalFavorites'];
      final withOffers = stats['favoritesWithOffers'];
      final percent = stats['percentageWithOffers'];

      if (mounted && total > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Favorites Summary"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Total favorites: $total",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("With active offers: $withOffers",
                      style: const TextStyle(color: Colors.green)),
                  Text("Percentage with offers: $percent%",
                      style: const TextStyle(color: Colors.blue)),
                  const SizedBox(height: 12),
                  const Text("Restaurants with offers today:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...vm.todaysDiscounts.map((r) => ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(r.imageUrl),
                          onBackgroundImageError: (_, __) {},
                        ),
                        title: Text(r.name),
                      )),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Ok"),
                ),
              ],
            ),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    print("🧹 Cerrando stream de favoritos...");
    Provider.of<RestaurantViewModel>(context, listen: false)
        .cancelFavoritesListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RestaurantViewModel>(
      builder: (context, vm, child) {
        if (vm.isLoadingFavorites) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vm.errorMessage != null) {
          return Center(child: Text("Error: ${vm.errorMessage}"));
        }

        if (vm.favorites.isEmpty) {
          return const Center(child: Text("No favorites yet"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vm.favorites.length,
          itemBuilder: (context, index) {
            final restaurant = vm.favorites[index];
            final hasActiveOffer =
                vm.todaysDiscounts.any((r) => r.id == restaurant.id);

            return InkWell(
              onTap: () async {
                final vm = Provider.of<RestaurantViewModel>(context, listen: false);

                // 🧩 NUEVO: Cargar detalle del restaurante desde cache o Firestore
                await vm.loadRestaurantDetail(restaurant.id);

                final detail = vm.selectedRestaurant ?? restaurant;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        UserRestaurantDetailPage(restaurant: detail),
                  ),
                );
              },
              child: Card(
                color: const Color.fromARGB(255, 170, 98, 153),
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < restaurant.rating.floor()
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              restaurant.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Type of food: ${restaurant.typeOfFood}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (hasActiveOffer)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  "Active Offer!",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: restaurant.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) => Image.asset(
                            'images/default.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        )
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
