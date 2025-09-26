import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:moviles/models/restaurant.dart';

import '/views/widget/restaurant_card.dart';
import '/views/pages/user/user_favorites_page.dart';
import '/views/pages/user/user_restaurant_detail_page.dart';
import '/views/pages/user/user_ofertas_page.dart';
import '/views/pages/user/user_review_history.dart';

class UserHomePage extends StatelessWidget {
  const UserHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
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
              InkWell(
                onTap: () {},
                child: const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color.fromARGB(255, 214, 145, 104),
                  child: Icon(Icons.person, color: Colors.white),
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Column(
              children: const [
                Divider(color: Colors.black, thickness: 1),
                TabBar(
                  tabAlignment: TabAlignment.fill,
                  isScrollable: false,
                  labelColor: Colors.black,
                  indicatorColor: Color.fromARGB(255, 214, 145, 104),
                  tabs: [
                    Tab(text: "Home"),
                    Tab(text: "Favorites"),
                    Tab(text: "Offers"),
                    Tab(text: "History review"),
                  ],
                ),
                Divider(color: Colors.black, thickness: 1),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            Column(
              children: [
                // Barra de búsqueda + filtro + chat
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
                          icon:
                              const Icon(Icons.filter_list, color: Colors.white),
                          onPressed: () {
                            // Aquí puedes dejar tu código de filtros
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 214, 145, 104),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.chat, color: Colors.white),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),

                // Mapa
                Container(
                  height: 200,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

                // Lista de restaurantes desde Firestore
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("Restaurants")
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final restaurants = snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return Restaurant(
                          id: doc.id,
                          name: data["name"] ?? "",
                          typeOfFood: data["typeOfFood"] ?? "",
                          rating: (data["rating"] != null)
                             ? double.tryParse(data["rating"].toString()) ?? 0.0
                              : 0.0,

                          offer: data["offer"] ?? "No offers",
                         imageUrl: data["imageUrl"] ??
                                "https://via.placeholder.com/150", // fallback online si no hay URL
                          address: '',
                          email: '',
                          location: '',
                          openingTime: 0,
                           closingTime: 0,
                        );
                      }).toList();

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: restaurants.length,
                        itemBuilder: (context, index) {
                          final restaurant = restaurants[index];
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      UserRestaurantDetailPage(
                                          restaurant: restaurant),
                                ),
                              );
                            },
                            child: RestaurantCard(restaurant: restaurant),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            const UserFavoritesPage(),
            const UserOfertasPage(),
            const UserReviewHistoryPage(),
          ],
        ),
      ),
    );
  }
}
