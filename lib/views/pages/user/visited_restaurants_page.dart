import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '/viewmodels/visit_viewmodel.dart';
import '/viewmodels/restaurant_viewmodel.dart';
import '/models/restaurant.dart';
import '/views/pages/user/user_restaurant_detail_page.dart';

class VisitedRestaurantsPage extends StatefulWidget {
  const VisitedRestaurantsPage({super.key});

  @override
  State<VisitedRestaurantsPage> createState() =>
      VisitedRestaurantsPageState();
}

class VisitedRestaurantsPageState extends State<VisitedRestaurantsPage> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isConnected = true;

  List<Map<String, dynamic>> visits = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _listenConnection();
    _loadVisited();
  }

  void _listenConnection() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final result =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
      setState(() => _isConnected = result != ConnectivityResult.none);
    });
  }

  Future<void> _loadVisited() async {
    final visitVM = Provider.of<VisitViewModel>(context, listen: false);

    final data = await visitVM.getUserVisitedRestaurants();

    // Order by most recent visit
    data.sort((a, b) {
      final DateTime dateB = b["visitedAt"] as DateTime;
      final DateTime dateA = a["visitedAt"] as DateTime;
      return dateB.compareTo(dateA);
    });

    setState(() {
      visits = data;
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (visits.isEmpty) {
      return const Center(child: Text("You haven't visited any restaurant yet"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: visits.length,
      itemBuilder: (context, index) {
        final visit = visits[index];
        final restaurantId = visit["restaurantId"];
        final visitedAt = visit["visitedAt"] as DateTime?;

        return FutureBuilder<Restaurant?>(
          future: Provider.of<RestaurantViewModel>(context, listen: false)
              .getRestaurantById(restaurantId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final restaurant = snapshot.data;

            if (restaurant == null) {
              return const SizedBox(
                height: 80,
                child: Center(child: Text("Restaurant not found")),
              );
            }

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserRestaurantDetailPage(
                      restaurant: restaurant,
                    ),
                  ),
                );
              },
              child: Card(
                color: Color.fromARGB(255, 170, 98, 153), // MORADO FUERTE
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ⭐ RATING
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

                            // NOMBRE
                            Text(
                              restaurant.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(height: 4),

                            // FECHA DE VISITA
                            Text(
                              "Visited on: ${visitedAt?.toLocal().toString().split(' ')[0]}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),

                            const SizedBox(height: 4),

                            // TIPO DE COMIDA
                            Text(
                              restaurant.typeOfFood,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // IMAGEN
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: restaurant.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(strokeWidth: 2),
                          errorWidget: (context, url, error) =>
                              Image.asset('images/default.png'),
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
