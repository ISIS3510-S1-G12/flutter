import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moviles/models/restaurant.dart';
import 'package:moviles/models/review.dart';
import '/repositories/review_repository.dart';
import 'restaurant_upload_menu_page.dart';
import 'edit_menu_page.dart';
import 'package:moviles/models/dish.dart';
import 'package:moviles/repositories/dish_repository.dart';

class RestaurantHomePage extends StatelessWidget {
  final String restaurantId;

  const RestaurantHomePage({super.key, required this.restaurantId});

  // Función para decodificar Base64
  Uint8List decodeBase64Image(String base64String) {
    final base64Data = base64String.split(',').last; // Quita prefijo data:image
    return base64Decode(base64Data);
  }

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
                // 🔹 Menu Tab
                SingleChildScrollView(
                  child: Column(
                    children: [
                      // Card del restaurante (imagen + nombre arriba)
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
                                      ? Image.memory(
                                          decodeBase64Image(
                                              restaurant.imageUrl),
                                          width: 64,
                                          height: 64,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error,
                                              stackTrace) {
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
                            options: MapOptions(maxZoom: 12.0),
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

                      // Botón Business Hours
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                        title:
                                            const Text("Business Hours"),
                                        content: Text(
                                            "Opening: ${restaurant.openingTime}:00\nClosing: ${restaurant.closingTime}:00"),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
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

                      // 🔹 Search Bar + Filter
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: "Search dishes...",
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  fillColor: Colors.grey[200],
                                  filled: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 214, 145, 104),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.filter_list,
                                    color: Colors.white),
                                onPressed: () {
                                  // Lógica de filtro
                                },
                              ),
                            )
                          ],
                        ),
                      ),

                      // Bloque azul con información del restaurante
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 107, 184, 194),
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                              Text("Type: ${restaurant.typeOfFood}",
                                  style: const TextStyle(color: Colors.white)),
                              const SizedBox(height: 4),
                              if (restaurant.offer) // ✅ ahora bool
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    "Offer Available 🎉",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.green),
                                  ),
                                ),
                              const SizedBox(height: 6),
                              Text("Address: ${restaurant.address}",
                                  style: const TextStyle(color: Colors.white)),
                              const SizedBox(height: 4),
                              Text("Email: ${restaurant.email}",
                                  style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),

                      // 🔹 Dishes del restaurante
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                                filterQuality: FilterQuality.low,
                                                cacheWidth: 60,
                                                cacheHeight: 60,
                                              )
                                            : const Icon(Icons.image_not_supported, size: 60),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                dish.name,
                                                style: const TextStyle(
                                                    fontSize: 16, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 4),
                                              Text("\$${dish.price.toStringAsFixed(2)}"),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: List.generate(
                                                  5,
                                                  (i) => Icon(
                                                    i < dish.rating ? Icons.star : Icons.star_border,
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

                      // Botones inferiores
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 39, 111, 121),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 16),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const RestaurantUploadMenuPage()),
                                  );
                                },
                                icon: const Icon(Icons.restaurant_menu),
                                label: const Text(
                                  "New Dish",
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color:
                                    const Color.fromARGB(255, 214, 145, 104),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 16),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => EditMenuPage(
                                            restaurantId: restaurant.id)),
                                  );
                                },
                                icon: const Icon(Icons.restaurant_outlined),
                                label: const Text(
                                  "Edit Menu",
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 🔹 Offers Tab
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: restaurant.offer
                        ? const Text("Offer Available 🎉")
                        : const Text("No offers available"),
                  ),
                ),

                // 🔹 Reviews Tab
                FutureBuilder<List<Review>>(
                  future:
                      ReviewRepository().getReviewsByRestaurant(restaurant.id),
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
}
