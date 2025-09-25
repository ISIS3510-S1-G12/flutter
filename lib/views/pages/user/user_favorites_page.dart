import 'package:flutter/material.dart';
import '/views/widget/restaurant_card.dart';
import '/views/pages/user/user_restaurant_detail_page.dart';

final List<Restaurant> restaurants = [
  Restaurant(
    id: "1",
    name: "La Bella Italia",
    typeOfFood: "Italiana",
    rating: 4.5,
    offer: "20% off",
    imageUrl: "images/laPuerta.png",
  ),
  Restaurant(
    id: "2",
    name: "Chicken Lovers",
    typeOfFood: "Pollo",
    rating: 4.0,
    offer: "15% off",
    imageUrl: "images/chickenLovers.png",
  ),
  Restaurant(
    id: "3",
    name: "Andres carne de res",
    typeOfFood: "Carne",
    rating: 3.5,
    offer: "Buy 1 Get 1",
    imageUrl: "images/andres.png",
  ),
  Restaurant(
    id: "4",
    name: "Chick & chips",
    typeOfFood: "Pollo",
    rating: 4,
    offer: "Buy 1 Get 1",
    imageUrl: "images/chicknchips.png",
  ),
];
class UserFavoritesPage extends StatelessWidget {
  

  const UserFavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search here...",
                    hintStyle: const TextStyle(color: Colors.white),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
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
              // Botón de filtro
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
                          top: Radius.circular(20),
                        ),
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
                                    title: const Text("With Offer"),
                                    value: filter2,
                                    onChanged: (val) {
                                      setState(() {
                                        filter2 = val ?? false;
                                      });
                                    },
                                  ),
                                  CheckboxListTile(
                                    title: const Text("Without Offer"),
                                    value: filter3,
                                    onChanged: (val) {
                                      setState(() {
                                        filter3 = val ?? false;
                                      });
                                    },
                                  ),
                                  CheckboxListTile(
                                    title: const Text("Fish"),
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
                      builder: (context) => UserRestaurantDetailPage(restaurant: restaurant),
                    ),
                  );
                },
                child: Card(
                  color: const Color.fromARGB(255, 170, 98, 153),
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
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Tipo de comida: ${restaurant.typeOfFood}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
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
                                    fontSize: 12,
                                    color: Colors.green,
                                  ),
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
    );
  }
}