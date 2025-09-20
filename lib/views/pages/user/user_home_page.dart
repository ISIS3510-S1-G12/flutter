import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '/views/pages/user/user_favorites_page.dart';
import '/views/widget/restaurant_card.dart';
import '/views/pages/user/user_restaurant_detail_page.dart';
import '/views/pages/user/user_ofertas_page.dart';
import '/views/pages/user/user_review_history.dart';


final List<Restaurant> restaurants = [
  Restaurant(
    name: "La Bella Italia",
    typeOfFood: "Italiana",
    rating: 4.5,
    offer: "20% off",
    imageUrl: "images/laPuerta.png",
  ),
  Restaurant(
    name: "Chicken Lovers",
    typeOfFood: "Pollo",
    rating: 4.0,
    offer: "15% off",
    imageUrl: "images/chickenLovers.png",
  ),
  Restaurant(
    name: "Andres carne de res",
    typeOfFood: "Carne",
    rating: 3.5,
    offer: "Buy 1 Get 1",
    imageUrl: "images/andres.png",
  ),
];

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
          bottom: TabBar(
            onTap: (index) {
              if (index == 1) { 
                Future.delayed(Duration.zero, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UserFavoritesPage()),
                  );
                });
              }
              if (index == 2) { // 👈 el índice del tab Offers
                Future.delayed(Duration.zero, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UserOfertasPage()),
                  );
                });
              }
              if (index == 3) { 
                Future.delayed(Duration.zero, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UserReviewHistoryPage()),
                  );
                });
              }
            },
            tabAlignment: TabAlignment.fill,
            isScrollable: false,
            labelColor: Colors.black,
            indicatorColor: Color.fromARGB(255, 214, 145, 104),
            labelPadding: EdgeInsets.symmetric(horizontal: 3.0),
            tabs: [
              Tab(text: "Home"),
              Tab(text: "Favorites"),
              Tab(text: "Offers"),
              Tab(text: "My Reviews"),
            ],
          ),
        ),
        body: Column(
          children: [
            // 🔹 Barra de búsqueda + filtro + chat
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search here...",
                        hintStyle: TextStyle(color: Colors.white),
                        prefixIcon: const Icon(Icons.search, color: Colors.white),
                        filled: true,
                        fillColor: Color.fromARGB(255, 214, 145, 104),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Botón de filtro
                  Container(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 214, 145, 104),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (BuildContext context) {
                            bool filter1 = false;
                            bool filter2 = false;
                            bool filter3 = false;
                            bool filter4 = false;

                            return StatefulBuilder(
                              builder: (context, setState) {
                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        "Filtros",
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 10),
                                      CheckboxListTile(
                                        title: const Text("Price"),
                                        value: filter1,
                                        onChanged: (val) {
                                          setState(() {
                                            filter1 = val ?? false;
                                          });
                                        },
                                      ),
                                      CheckboxListTile(
                                        title: const Text("Type of Food"),
                                        value: filter2,
                                        onChanged: (val) {
                                          setState(() {
                                            filter2 = val ?? false;
                                          });
                                        },
                                      ),
                                      CheckboxListTile(
                                        title: const Text("With Offer"),
                                        value: filter3,
                                        onChanged: (val) {
                                          setState(() {
                                            filter3 = val ?? false;
                                          });
                                        },
                                      ),
                                      CheckboxListTile(
                                        title: const Text("Without Offer"),
                                        value: filter4,
                                        onChanged: (val) {
                                          setState(() {
                                            filter4 = val ?? false;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                      ElevatedButton(
                                        onPressed: () {
                                          print(
                                              "Filtros aplicados: $filter1, $filter2, $filter3, $filter4");
                                          Navigator.pop(context);
                                        },
                                        child: const Text("Apply Filters"),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Botón de chat
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
                      urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: 'com.example.moviles',
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: restaurants.length,
                itemBuilder: (context, index) {
                  final restaurant = restaurants[index];
                  return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserRestaurantDetailPage(
              ),
            ),
          );
        },
                  child: Card(
                    color: Color.fromARGB(255,170,98,153),
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
                                      color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Tipo de comida: ${restaurant.typeOfFood}",
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "Offers: ${restaurant.offer}",
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.green),
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
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
