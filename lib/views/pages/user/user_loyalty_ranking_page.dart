import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:moviles/viewmodels/visit_viewmodel.dart';
import 'package:moviles/views/pages/user/user_restaurant_detail_page.dart';
import 'package:moviles/models/restaurant.dart';

class UserLoyaltyRankingPage extends StatelessWidget {
  const UserLoyaltyRankingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final visitVM = Provider.of<VisitViewModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Top Restaurants by Loyalty"),
        backgroundColor: const Color.fromARGB(255, 214, 145, 104),
      ),
      body: FutureBuilder<Map<String, double>>(
        // 🔹 Estrategia Future: obtener loyalty rates
        future: visitVM.getWeeklyLoyaltyRates(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final loyaltyRates = snapshot.data!;
          if (loyaltyRates.isEmpty) {
            return const Center(child: Text("No visits recorded this week."));
          }

          // Ordenar por loyalty desc
          final sorted = loyaltyRates.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          // 🔹 StreamBuilder: actualizar lista de restaurantes en tiempo real
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("Restaurants").snapshots(),
            builder: (context, restaurantSnapshot) {
              if (!restaurantSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = restaurantSnapshot.data!.docs;

              return ListView.builder(
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final restaurantId = sorted[index].key;
                  final loyalty = sorted[index].value;

                  // 🔹 Opción 2: evitar firstWhere con orElse
                  final filteredDocs = docs.where((d) => d.id == restaurantId);
                  if (filteredDocs.isEmpty) return const SizedBox.shrink();
                  final doc = filteredDocs.first;

                  final data = doc.data() as Map<String, dynamic>;
                  final restaurant = Restaurant(
                    id: restaurantId,
                    name: data['name'] ?? '',
                    imageUrl: data['imageUrl'] ?? '',
                    typeOfFood: data['typeOfFood'] ?? '',
                    rating: (data['rating'] ?? 0).toDouble(),
                    offer: data['offer'] ?? false,
                    address: data['address'] ?? '',
                    email: data['email'] ?? '',
                    openingTime: int.tryParse(data['opening_time']?.toString() ?? '0') ?? 0,
                    closingTime: int.tryParse(data['closing_time']?.toString() ?? '0') ?? 0,
                  );

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: restaurant.imageUrl.isNotEmpty
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(restaurant.imageUrl),
                              radius: 28,
                            )
                          : const CircleAvatar(
                              radius: 28,
                              child: Icon(Icons.restaurant, color: Colors.white),
                              backgroundColor: Color.fromARGB(255, 214, 145, 104),
                            ),
                      title: Text(restaurant.name),
                      subtitle: Text("Loyalty rate: ${(loyalty * 100).toStringAsFixed(1)}%"),
                      trailing: index == 0
                          ? const Icon(Icons.star, color: Colors.amber)
                          : null,
                      // 🔹 Future con handler: al hacer tap, obtenemos el restaurante con .then()
                      onTap: () {
                        FirebaseFirestore.instance
                            .collection("Restaurants")
                            .doc(restaurantId)
                            .get()
                            .then((restaurantDoc) {
                          if (!restaurantDoc.exists) return;
                          final data = restaurantDoc.data()!;
                          final tappedRestaurant = Restaurant(
                            id: restaurantId,
                            name: data['name'] ?? '',
                            imageUrl: data['imageUrl'] ?? '',
                            typeOfFood: data['typeOfFood'] ?? '',
                            rating: (data['rating'] ?? 0).toDouble(),
                            offer: data['offer'] ?? false,
                            address: data['address'] ?? '',
                            email: data['email'] ?? '',
                            openingTime: int.tryParse(data['opening_time']?.toString() ?? '0') ?? 0,
                            closingTime: int.tryParse(data['closing_time']?.toString() ?? '0') ?? 0,
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserRestaurantDetailPage(restaurant: tappedRestaurant),
                            ),
                          );
                        });
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
