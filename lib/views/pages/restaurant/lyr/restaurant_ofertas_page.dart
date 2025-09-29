import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/restaurant.dart';

class RestaurantOfertasPage extends StatelessWidget {
  const RestaurantOfertasPage({super.key});

  Future<List<Restaurant>> fetchRestaurants() async {
    final snapshot = await FirebaseFirestore.instance.collection('restaurants').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Restaurant(
        id: doc.id,
        name: data['name'] ?? '',
        typeOfFood: data['typeOfFood'] ?? '',
        rating: (data['rating'] ?? 0).toDouble(),
        offer: data['offer'] ?? '',
        imageUrl: data['imageUrl'] ?? 'images/default.png', address: '', email: '', location: '', openingTime: 0, closingTime: 0,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  "images/483891256-e6bd4888-8904-4028-911f-dff62cc98965.png",
                  height: MediaQuery.of(context).size.height * 0.08,
                ),
                InkWell(
                  onTap: () {},
                  child: const CircleAvatar(
                    radius: 28,
                    backgroundColor: Color.fromARGB(255, 214, 145, 104),
                    child: Icon(Icons.restaurant, color: Colors.white),
                  ),
                ),
              ],
            ),
            const Divider(
              thickness: 1,
              color: Colors.grey,
              height: 1,
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<Restaurant>>(
        future: fetchRestaurants(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final restaurants = snapshot.data ?? [];

          return Column(
            children: [
              // 🔹 FlutterMap
              Container(
                height: 200,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    options: MapOptions(
                      onTap: (tapPosition, latLng) {
                        print("Tapped at: $latLng");
                      },
                      maxZoom: 12.0,
                    ),
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

              const SizedBox(height: 8),

              // 🔹 Barra de búsqueda + filtro (igual que antes)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Search here...",
                          hintStyle: const TextStyle(color: Colors.white),
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.white),
                          filled: true,
                          fillColor: const Color.fromARGB(255, 214, 145, 104),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 214, 145, 104),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.filter_list, color: Colors.white),
                        onPressed: () {
                          // Aquí puedes mantener tu modal de filtros
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // 🔹 Lista de restaurantes
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: restaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = restaurants[index];
                    return Card(
                      color: const Color.fromARGB(255, 107, 184, 194),
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
                                        i < restaurant.rating!.floor()
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
                                        color: Colors.white),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Description: ${restaurant.typeOfFood}",
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.white),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          const Color.fromARGB(255, 39, 111, 121),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      "Edit",
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                restaurant.imageUrl,
                                width: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
