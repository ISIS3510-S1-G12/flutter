import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/viewmodels/restaurant_viewmodel.dart';
import '/models/restaurant.dart';
import '/views/pages/user/user_restaurant_detail_page.dart';

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
      await vm.fetchFavorites();

      if (vm.totalFavorites > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Favorites Summary"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total favorites: ${vm.totalFavorites}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "With active offers: ${vm.favoritesWithOffers}",
                    style: const TextStyle(color: Colors.green),
                  ),
                  Text(
                    "Percentage with offers: ${vm.percentageWithOffers}%",
                    style: const TextStyle(color: Colors.blue),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Restaurants with offers today:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
            final Restaurant restaurant = vm.favorites[index];
            final bool hasActiveOffer = vm.todaysDiscounts
                .any((r) => r.id == restaurant.id); // 🔹 check real offers

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        UserRestaurantDetailPage(restaurant: restaurant),
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
                        child: Image.network(
                          restaurant.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'images/default.png',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
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