import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moviles/models/restaurant.dart';
import 'package:moviles/views/pages/user/user_restaurant_detail_page.dart';

class TopRatedRestaurantsPage extends StatelessWidget {
  const TopRatedRestaurantsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Top Rated Restaurants"),
        backgroundColor: const Color.fromARGB(255, 214, 145, 104),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("Restaurants")
            .orderBy("rating", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text("No restaurants found."),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final restaurant = Restaurant(
                id: doc.id,
                name: data['name'] ?? '',
                imageUrl: data['imageUrl'] ?? '',
                typeOfFood: data['typeOfFood'] ?? '',
                rating: (data['rating'] ?? 0).toDouble(),
                offer: data['offer'] ?? false,
                address: data['address'] ?? '',
                email: data['email'] ?? '',
                openingTime:
                    int.tryParse(data['opening_time']?.toString() ?? '0') ?? 0,
                closingTime:
                    int.tryParse(data['closing_time']?.toString() ?? '0') ?? 0,
              );

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  // 🔥 MISMA LÓGICA DE IMAGEN QUE UserLoyaltyRankingPage
                  leading: restaurant.imageUrl.isNotEmpty
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(restaurant.imageUrl),
                          radius: 28,
                        )
                      : const CircleAvatar(
                          radius: 28,
                          child: Icon(Icons.restaurant, color: Colors.white),
                          backgroundColor:
                              Color.fromARGB(255, 214, 145, 104),
                        ),

                  title: Text(restaurant.name),
                  subtitle:
                      Text("Rating: ${restaurant.rating.toStringAsFixed(1)} ⭐"),

                  trailing: index == 0
                      ? const Icon(Icons.star, color: Colors.amber)
                      : null,

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            UserRestaurantDetailPage(restaurant: restaurant),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
