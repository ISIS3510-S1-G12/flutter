import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '/viewmodels/restaurant_viewmodel.dart';
import '/models/restaurant.dart';
import '/views/pages/user/user_restaurant_detail_page.dart';

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
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();

  _connectivitySubscription =
      Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
    final bool connected = !results.contains(ConnectivityResult.none);

    if (connected != _isConnected) {
      setState(() {
        _isConnected = connected;
      });

      if (connected) {
        debugPrint(" Connection restored on OfferFormPage");
        _showOnlineDialog();
      } else {
        debugPrint("No connection on OfferFormPage");
        _showOfflineDialog();
      }
    }
  });



    Future.microtask(() async {
      final vm = Provider.of<RestaurantViewModel>(context, listen: false);

      await vm.fetchFavorites(fromCache: true);
      vm.listenToFavoritesStream();
      await vm.fetchFavorites();

      if (vm.favorites.isEmpty) return;

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
                  Text("Total favorites: $total"),
                  Text("With active offers: $withOffers"),
                  Text("Percentage with offers: $percent%"),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        });
      }
    });
  }

  void _showOfflineDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Offline Mode"),
        content: const Text(
          "You’re currently offline.\nFavorites will still be shown using cached data.",
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showOnlineDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Back Online"),
        content: const Text(
          "Your connection has been restored.\nYou can now see all your favorite restaurants information.",
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
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
