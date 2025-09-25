import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:moviles/views/pages/restaurant/lyr/restaurant_ofertas_page.dart';

import '/views/widget/restaurant_card.dart';
import 'restaurant_upload_menu_page.dart'; // 👈 importa tu nueva página

final List<Restaurant> restaurants = [
  Restaurant(
    id: "1",
    name: "Bacon Sandwich",
    typeOfFood: "ANVORGUESA CON BACON",
    rating: 4.5,
    offer: "20% off",
    imageUrl: "images/bacon.png",
  ),
  Restaurant(
    id: "2",
    name: "bbq Sandwich",
    typeOfFood: "ANVORGUESA CON BBQ",
    rating: 4.0,
    offer: "15% off",
    imageUrl: "images/bbq.png",
  ),
  Restaurant(
    id: "3",
    name: "Chicken Sandwich",
    typeOfFood: "ANVORGUESA CON POLLO",
    rating: 3.5,
    offer: "Buy 1 Get 1",
    imageUrl: "images/pollo.png",
  ),
];

class RestaurantHomePage extends StatelessWidget {
  const RestaurantHomePage({super.key});

  @override
  Widget build(BuildContext context) {
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
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Column(
              children: [
                // 🔹 Línea debajo del header (logo + avatar)
                Divider(
                  thickness: 1,
                  color: Colors.black,
                  height: 1,
                ),
                // 🔹 Tabs
                TabBar(
                  onTap: (index) {
                    if (index == 1) {
                      Future.delayed(Duration.zero, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RestaurantOfertasPage(),
                          ),
                        );
                      });
                    }
                  },
                  tabAlignment: TabAlignment.fill,
                  isScrollable: false,
                  labelColor: Colors.black,
                  indicatorColor: const Color.fromARGB(255, 214, 145, 104),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 3.0),
                  tabs: const [
                    Tab(text: "Menu"),
                    Tab(text: "Offers"),
                    Tab(text: "Reviews"),
                  ],
                ),
                // 🔹 Línea debajo de los Tabs
                Divider(
                  thickness: 1,
                  color: Colors.black,
                  height: 1,
                ),
              ],
            ),
          ),
        ),
        body: Column(
          children: [
            // 🔹 Mapa
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

            // 🔹 Botón Busiest Hours
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
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
                    print("Busiest Hours pressed");
                  },
                  icon: const Icon(Icons.bar_chart),
                  label: const Text(
                    "Busiest Hours",
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 🔹 Barra de búsqueda + filtro
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
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20)),
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
                                        title: const Text("Cheapest"),
                                        value: filter1,
                                        onChanged: (val) {
                                          setState(() {
                                            filter1 = val ?? false;
                                          });
                                        },
                                      ),
                                      CheckboxListTile(
                                        title: const Text("Most Ordered"),
                                        value: filter2,
                                        onChanged: (val) {
                                          setState(() {
                                            filter2 = val ?? false;
                                          });
                                        },
                                      ),
                                      CheckboxListTile(
                                        title: const Text("Restaurant Favorites"),
                                        value: filter3,
                                        onChanged: (val) {
                                          setState(() {
                                            filter3 = val ?? false;
                                          });
                                        },
                                      ),
                                      CheckboxListTile(
                                        title: const Text("Highest Discount"),
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
                                          print("Filtros aplicados");
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
                ],
              ),
            ),

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
                                  "Description: ${restaurant.typeOfFood}",
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 39, 111, 121),
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

            // 🔹 Botones inferiores
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                              builder: (_) => const RestaurantUploadMenuPage()),
                        );
                      },
                      icon: const Icon(Icons.restaurant_menu),
                      label: const Text(
                        "New Dish",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 214, 145, 104),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                      ),
                      onPressed: () {
                        print("Edit Menu pressed");
                      },
                      icon: const Icon(Icons.restaurant_outlined),
                      label: const Text(
                        "Edit Menu",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
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
  }
}
