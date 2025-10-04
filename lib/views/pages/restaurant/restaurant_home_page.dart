import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moviles/models/restaurant.dart';
import 'package:moviles/models/review.dart';
import '/repositories/review_repository.dart';
import 'edit_menu_page.dart';
import 'package:moviles/models/dish.dart';
import 'package:moviles/repositories/dish_repository.dart';
import 'restaurant_offers_page.dart';

class RestaurantHomePage extends StatelessWidget {
  final String restaurantId;

  const RestaurantHomePage({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Restaurants')
          .doc(restaurantId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        if (data == null) {
          return const Scaffold(
              body: Center(child: Text("Restaurant not found")));
        }

        final restaurant = Restaurant(
          id: snapshot.data!.id,
          name: data['name'] ?? '',
          typeOfFood: data['typeOfFood'] ?? '',
          rating: (data['rating'] is num)
              ? (data['rating'] as num).toDouble()
              : 0.0,
          offer: data['offer'] ?? false,
          imageUrl: data['imageUrl'] ?? '',
          address: data['address'] ?? '',
          email: data['email'] ?? '',
          openingTime:
              int.tryParse(data['opening_time']?.toString() ?? '0') ?? 0,
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
                // -------- MENU TAB --------
                _buildMenuTab(restaurant, context),

                // -------- OFFERS TAB --------
                RestaurantOffersPage(restaurantId: restaurant.id),

                // -------- REVIEWS TAB --------
                FutureBuilder<List<Review>>(
                  future: ReviewRepository()
                      .getReviewsByRestaurant(restaurant.id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator());
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.grey,
                                      child: Icon(Icons.person,
                                          color: Colors.white),
                                    ),
                                    const SizedBox(width: 8),
                                    // 🔥 Aquí buscamos el nombre del usuario en Firestore
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
                                            .data() as Map<String, dynamic>?;
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Extraí el Menu Tab a un método privado para que no quede tan largo ---
  Widget _buildMenuTab(Restaurant restaurant, BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Card restaurante
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
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.image_not_supported,
                                  size: 64,
                                  color: Colors.white,
                                );
                              },
                            )
                          : const Icon(
                              Icons.image_not_supported,
                              size: 64,
                              color: Colors.white,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        restaurant.name,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Botón business hours
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                            title: const Text("Business Hours"),
                            content: Text(
                                "Opening: ${restaurant.openingTime}:00\nClosing: ${restaurant.closingTime}:00"),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Close"))
                            ],
                          ));
                },
                icon: const Icon(Icons.access_time),
                label: const Text("Business Hours"),
                style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color.fromARGB(255, 214, 145, 104)),
              ),
            ),
          ),

          // Platos
          StreamBuilder<List<Dish>>(
            stream: DishRepository().getDishesByRestaurant(restaurant.id),
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

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        title: Text(dish.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
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

          // Botón New Dish
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 214, 145, 104),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditMenuPage(
                          restaurantId: restaurant.id,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.restaurant_outlined),
                  label: const Text(
                    "New Dish",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
