import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/restaurant.dart';
import '/models/review.dart';
import '/models/dish.dart';
import '/repositories/review_repository.dart';
import '/repositories/dish_repository.dart';
import '/views/widget/restaurant_detail_card.dart';
import '/views/pages/user/write_review_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRestaurantDetailPage extends StatefulWidget {
  final Restaurant restaurant;
  const UserRestaurantDetailPage({super.key, required this.restaurant});

  @override
  State<UserRestaurantDetailPage> createState() =>
      _UserRestaurantDetailPageState();
}

class _UserRestaurantDetailPageState extends State<UserRestaurantDetailPage> {
  bool isFavorite = false;

  // Función para decodificar Base64
  Uint8List decodeBase64Image(String base64String) {
    final base64Data = base64String.split(',').last;
    return base64Decode(base64Data);
  }

  String formatTime(int time) {
    if (time < 0 || time > 2359) return "--:--";
    final hour = (time ~/ 100).toString().padLeft(2, '0');
    final minute = (time % 100).toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  Future<void> toggleFavorite(Restaurant restaurant) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final favRef = FirebaseFirestore.instance
        .collection('Favorites')
        .doc(user.uid)
        .collection('Restaurants')
        .doc(restaurant.id);

    final snapshot = await favRef.get();

    if (snapshot.exists) {
      await favRef.delete();
      setState(() => isFavorite = false);
    } else {
      await favRef.set({
        'restaurant_id': FirebaseFirestore.instance
            .collection('Restaurants')
            .doc(restaurant.id),
        'name': restaurant.name,
        'imageUrl': restaurant.imageUrl,
        'offer': restaurant.offer,
        'typeOfFood': restaurant.typeOfFood,
        'addedAt': FieldValue.serverTimestamp(),
      });
      setState(() => isFavorite = true);
    }
  }

  Future<void> checkIfFavorite(Restaurant restaurant) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final favRef = FirebaseFirestore.instance
        .collection('Favorites')
        .doc(user.uid)
        .collection('Restaurants')
        .doc(restaurant.id);

    final snapshot = await favRef.get();
    setState(() => isFavorite = snapshot.exists);
  }

  @override
  void initState() {
    super.initState();
    checkIfFavorite(widget.restaurant);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("Restaurants")
          .doc(widget.restaurant.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        final fullRestaurant = Restaurant(
          id: widget.restaurant.id,
          name: data['name'] ?? '',
          typeOfFood: data['typeOfFood'] ?? '',
          rating: (data['rating'] != null)
              ? double.tryParse(data['rating'].toString()) ?? 0.0
              : 0.0,
          offer: data['offer'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          address: data['address'] ?? '',
          location: data['location'] ?? '',
          openingTime: data['openingTime'] ?? 0,
          closingTime: data['closingTime'] ?? 0,
          email: data['email'] ?? '',
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
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ],
              ),
              bottom: TabBar(
                labelColor: Colors.black,
                indicatorColor: const Color.fromARGB(255, 214, 145, 104),
                tabs: const [
                  Tab(text: "Menu"),
                  Tab(text: "Offers"),
                  Tab(text: "Reviews"),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                // 🔹 Menu Tab
                SingleChildScrollView(
                  child: Column(
                    children: [
                      RestaurantDetailCard(restaurant: fullRestaurant),

                      // Botón favorito
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ElevatedButton.icon(
                          onPressed: () => toggleFavorite(fullRestaurant),
                          icon: Icon(isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border),
                          label: Text(isFavorite
                              ? "Marked as Favorite"
                              : "Mark as Favorite"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 121, 39, 101),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),

                      // Mapa
                      Container(
                        height: 200,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FlutterMap(
                            options: MapOptions(maxZoom: 13.0),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                                userAgentPackageName: 'com.example.moviles',
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 🔹 Dishes del restaurante
                      StreamBuilder<List<Dish>>(
                        stream: DishRepository()
                            .getDishesByRestaurant(fullRestaurant.id),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Column(
                              children: dishes.map((dish) {
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      children: [
                                        dish.imageUrl.isNotEmpty
                                            ? Image.memory(
                                                decodeBase64Image(dish.imageUrl),
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                                cacheWidth: 60,
                                                cacheHeight: 60,
                                              )
                                            : const Icon(Icons.image_not_supported,
                                                size: 60),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                dish.name,
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                  "\$${dish.price.toStringAsFixed(2)}"),
                                              const SizedBox(height: 2),
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
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // 🔹 Offers Tab
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: (fullRestaurant.offer ?? '').isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              fullRestaurant.offer ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                          )
                        : const Center(child: Text("No offers available.")),
                  ),
                ),

                // 🔹 Reviews Tab
                FutureBuilder<List<Review>>(
                  future: ReviewRepository()
                      .getReviewsByRestaurant(fullRestaurant.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final reviews = snapshot.data ?? [];
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
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                if (review.photoUrl != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Image.network(
                                      review.photoUrl!,
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

            // 🔹 Botón review
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 121, 39, 101),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            WriteReviewPage(restaurantId: fullRestaurant.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text("Write a Review"),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
