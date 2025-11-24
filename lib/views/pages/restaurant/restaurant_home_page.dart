import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moviles/models/restaurant.dart';
import 'package:moviles/models/review.dart';
import '/repositories/review_repository.dart';
import 'edit_menu_page.dart';
import 'package:moviles/models/dish.dart';
import 'package:moviles/repositories/dish_repository.dart';
import 'restaurant_offers_page.dart';
import 'package:provider/provider.dart';
import 'package:moviles/viewmodels/visit_viewmodel.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:isolate';

class RestaurantHomePage extends StatefulWidget {
  final String restaurantId;

  const RestaurantHomePage({super.key, required this.restaurantId});

  @override
  State<RestaurantHomePage> createState() => _RestaurantHomePageState();
}

class _RestaurantHomePageState extends State<RestaurantHomePage> {
  late final Stream<List<Dish>> _dishesStream;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();

    final dishRepository = DishRepository();

    _dishesStream =
        dishRepository.getDishesByRestaurant(widget.restaurantId).asBroadcastStream();

    Connectivity().onConnectivityChanged.listen((status) async {
      final offlineNow = status == ConnectivityResult.none;

      if (mounted && offlineNow != _isOffline) {
        setState(() {
          _isOffline = offlineNow;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: offlineNow ? Colors.red : Colors.green,
            content: Text(
              offlineNow
                  ? "Offline mode: No internet connection"
                  : "Back online",
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      if (status != ConnectivityResult.none) {
        await dishRepository.syncLocalDishes();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Restaurants')
              .doc(widget.restaurantId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data = snapshot.data!.data() as Map<String, dynamic>?;

            if (data == null) {
              return const Scaffold(
                body: Center(child: Text("Restaurant not found")),
              );
            }

            final restaurant = Restaurant(
              id: snapshot.data!.id,
              name: data['name'] ?? '',
              typeOfFood: data['typeOfFood'] ?? '',
              rating:
                  (data['rating'] is num) ? (data['rating'] as num).toDouble() : 0.0,
              offer: data['offer'] ?? false,
              imageUrl: data['imageUrl'] ?? '',
              address: data['address'] ?? '',
              email: data['email'] ?? '',
              openingTime: int.tryParse(data['opening_time']?.toString() ?? '0') ?? 0,
              closingTime:
                  int.tryParse(data['closing_time']?.toString() ?? '0') ?? 0,
            );

            return DefaultTabController(
              length: 3,
              child: Scaffold(
                backgroundColor: Colors.white,
                appBar: AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        "images/483891256-e6bd4888-8904-4028-911f-dff62cc98965.png",
                        height: MediaQuery.of(context).size.height * 0.08,
                      ),
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Color.fromARGB(255, 214, 145, 104),
                        child: Icon(Icons.restaurant, color: Colors.white),
                      ),
                    ],
                  ),
                  bottom: const PreferredSize(
                    preferredSize: Size.fromHeight(70),
                    child: Column(
                      children: [
                        Divider(thickness: 1, color: Colors.black, height: 1),
                        TabBar(
                          tabAlignment: TabAlignment.fill,
                          isScrollable: false,
                          labelColor: Colors.black,
                          indicatorColor: Color.fromARGB(255, 214, 145, 104),
                          tabs: [
                            Tab(text: "Menu"),
                            Tab(text: "Offers"),
                            Tab(text: "Reviews"),
                          ],
                        ),
                        Divider(thickness: 1, color: Colors.black, height: 1),
                      ],
                    ),
                  ),
                ),
                body: TabBarView(
                  children: [
                    _buildMenuTab(context, restaurant),
                    RestaurantOffersPage(restaurantId: restaurant.id),
                    _buildReviewsTab(restaurant),
                  ],
                ),
              ),
            );
          },
        ),

        if (_isOffline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.red,
              padding: const EdgeInsets.all(8),
              child: const SafeArea(
                child: Text(
                  "⚠️ Offline — No internet connection",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // =========================
  //       MENU TAB
  // =========================
  Widget _buildMenuTab(BuildContext context, Restaurant restaurant) {
    final visitVM = context.read<VisitViewModel>();

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 12),

          FutureBuilder<Map<String, int>>(
            future: visitVM.getWeeklyVisitCounts(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox();
              }
              final visits = snapshot.data!;
              final mostVisited =
                  visits.entries.reduce((a, b) => a.value > b.value ? a : b);

              if (mostVisited.key != restaurant.id) return const SizedBox();

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "🏆 You are the most visited restaurant this week!",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          FutureBuilder<Map<String, double>>(
            future: visitVM.getWeeklyLoyaltyRates(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox();
              }

              final loyaltyRates = snapshot.data!;
              final rate = loyaltyRates[restaurant.id] ?? 0.0;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 214, 145, 104).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: const Color.fromARGB(255, 214, 145, 104)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.repeat, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      "Loyalty Rate: ${(rate * 100).toStringAsFixed(1)}%",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ============================================================
          //     INFO DEL RESTAURANTE (AQUÍ AGREGUÉ EL RATING DINÁMICO)
          // ============================================================
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: const Color.fromARGB(255, 107, 184, 194),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: restaurant.imageUrl.isNotEmpty
                          ? Image.network(
                              restaurant.imageUrl,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.image_not_supported,
                              size: 64, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            restaurant.name,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),

                          const SizedBox(height: 6),

                          // ⭐⭐⭐⭐⭐ RATING CALCULADO SEGÚN REVIEWS
                          FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance
                                .collection("Reviews")
                                .where("restaurant_id", isEqualTo: restaurant.id)
                                .get(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const SizedBox(
                                  height: 20,
                                  child: LinearProgressIndicator(),
                                );
                              }

                              final reviews = snapshot.data!.docs;

                              if (reviews.isEmpty) {
                                return const Text(
                                  "Rating: No reviews yet",
                                  style: TextStyle(color: Colors.white),
                                );
                              }

                              double avg = 0;
                              for (var r in reviews) {
                                avg += (r["stars"] ?? 0).toDouble();
                              }
                              avg /= reviews.length;

                              return Row(
                                children: [
                                  Text(
                                    "Rating: ${avg.toStringAsFixed(1)} ",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  ...List.generate(
                                    5,
                                    (i) => Icon(
                                      i < avg ? Icons.star : Icons.star_border,
                                      color: Colors.amber,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              );
                            },
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),



          StreamBuilder<List<Dish>>(
            stream: _dishesStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final dishes = snapshot.data!;
              if (dishes.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("No dishes yet."),
                );
              }

              _processDishesInIsolate(dishes);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: dishes.map((dish) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: dish.imageUrl.isNotEmpty
                            ? Image.network(
                                dish.imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.image_not_supported, size: 60),
                        title: Text(
                          dish.name,
                          style:
                              const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("\$${dish.price.toStringAsFixed(2)}"),
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < dish.rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),

          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isOffline
                  ? Colors.grey
                  : const Color.fromARGB(255, 214, 145, 104),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: _isOffline
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EditMenuPage(restaurantId: restaurant.id),
                      ),
                    );
                  },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Create Dish",
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // =========================
  //       REVIEWS TAB
  // =========================
  Widget _buildReviewsTab(Restaurant restaurant) {
    return FutureBuilder<List<Review>>(
      future: ReviewRepository().getReviewsByRestaurant(restaurant.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final reviews = snapshot.data!;
        if (reviews.isEmpty) {
          return const Center(child: Text("No reviews yet."));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey,
                          child:
                              Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('Users')
                              .doc(review.userId)
                              .get(),
                          builder: (context, userSnapshot) {
                            if (!userSnapshot.hasData) {
                              return const Text("Loading...");
                            }
                            final userData = userSnapshot.data!
                                    .data()
                                as Map<String, dynamic>?;
                            final userName =
                                userData?['name'] ?? "Unknown User";
                            return Text(
                              userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < review.stars
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(review.comment),
                    if (review.imageUrl != null &&
                        review.imageUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Image.network(
                          review.imageUrl!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _processDishesInIsolate(List<Dish> dishes) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(_heavyDishProcessing, [receivePort.sendPort, dishes]);

    await for (var message in receivePort) {
      debugPrint(
          "Average dish price processed in isolate: \$${message.toStringAsFixed(2)}");
      break;
    }
  }

  static void _heavyDishProcessing(List<dynamic> args) {
    SendPort sendPort = args[0];
    List<Dish> dishes = args[1];

    if (dishes.isEmpty) {
      sendPort.send(0.0);
      return;
    }

    double total = 0;
    for (var dish in dishes) {
      total += dish.price;
    }
    final avgPrice = total / dishes.length;
    sendPort.send(avgPrice);
  }
}
