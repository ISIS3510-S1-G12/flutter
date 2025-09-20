import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';
import '/views/widget/restaurant_card.dart';



final List<Restaurant> restaurants = [
  Restaurant(
    name: "Bacon Sandwich",
    typeOfFood: "ANVORGUESA CON BACON",
    rating: 4.5,
    offer: "20% off",
    imageUrl: "images/bacon.png",
  ),
  Restaurant(
    name: "bbq Sandwich",
    typeOfFood: "ANVORGUESA CON BBQ",
    rating: 4.0,
    offer: "15% off",
    imageUrl: "images/bbq.png",
  ),
  Restaurant(
    name: "Chicken Sandwich",
    typeOfFood: "ANVORGUESA CON POLLO",
    rating: 3.5,
    offer: "Buy 1 Get 1",
    imageUrl: "images/pollo.png",
  ),
];

class UserRestaurantDetailPage extends StatelessWidget {
  const UserRestaurantDetailPage({super.key});

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
                  child: Icon(Icons.person, color: Colors.white),
                ),
              ),
            ],
          ),
          bottom: const TabBar(
            isScrollable: false,
            labelColor: Colors.black,
            indicatorColor: Color.fromARGB(255, 214, 145, 104),
            labelPadding: EdgeInsets.symmetric(horizontal: 3.0),
            tabs: [
              Tab(text: "Menu"),
              Tab(text: "Offers"),
              Tab(text: "Reviews"),
            ],
          ),
        ),
        body: Column(
          children: [

            const SizedBox(height: 8),
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

// 🔹 Nuevo botón tipo "Busiest Hours"
Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [  
   Container(
    decoration: BoxDecoration(
      color: Color.fromARGB(255, 121, 39, 101), // verde-azulado como la imagen
      borderRadius: BorderRadius.circular(8),
    ),
    child: TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white, // texto e ícono blancos
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      ),
      onPressed: () {
        print("Busiest Hours pressed");
        // aquí puedes navegar o abrir un gráfico
      },
      icon: const Icon(Icons.bar_chart), // ícono de gráfico
      label: const Text(
        "Busiest Hours",
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    ),
  ),
  Container(
    decoration: BoxDecoration(
      color: Color.fromARGB(255, 121, 39, 101), // verde-azulado como la imagen
      borderRadius: BorderRadius.circular(8),
    ),
    child: TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white, // texto e ícono blancos
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      ),
      onPressed: () {
        print("Marked as Favorite");
        // aquí puedes navegar o abrir un gráfico
      },
      icon: const Icon(Icons.star), // ícono de gráfico
      label: const Text(
        "Mark as Favorite",
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    ),
  ),
  ],
  ),),

            const SizedBox(height: 8),
            // 🔹 Lista de restaurantes
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: restaurants.length,
                itemBuilder: (context, index) {
                  final restaurant = restaurants[index];
                  return Card(
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
                                  "Description: ${restaurant.typeOfFood}",
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.white),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
    children: [  
   Container(
    decoration: BoxDecoration(
      color: Color.fromARGB(255, 121, 39, 101), // verde-azulado como la imagen
      borderRadius: BorderRadius.circular(8),
    ),
    child: TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white, // texto e ícono blancos
      ),
      onPressed: () {
        print("Create New Dish");
        // aquí puedes navegar o abrir un gráfico
      },
      icon: const Icon(Icons.edit), // ícono de gráfico
      label: const Text(
        "Write a Review",
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    ),
  ),
  
  ],
  ),),
          ],
        ),
      ),
    );
  }
}