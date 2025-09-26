import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/views/pages/user/user_restaurant_detail_page.dart';
import '/models/restaurant.dart';

class UserFavoritesPage extends StatelessWidget {
  const UserFavoritesPage({super.key});

  Uint8List decodeBase64Image(String base64String) {
    final base64Data = base64String.split(',').last;
    return base64Decode(base64Data);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('No user logged in'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Favorites')
          .doc(user.uid)
          .collection('Restaurants')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final restaurants = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Restaurant(
            id: doc.id,
            name: data['name'] ?? '',
            typeOfFood: data['typeOfFood'] ?? '',
            rating: (data['rating'] != null)
                ? double.tryParse(data['rating'].toString()) ?? 0.0
                : 0.0,
            offer: data['offer'] ?? '',
            imageUrl: data['imageUrl'] ?? '',
            address: data['address'] ?? '',
            email: data['email'] ?? '',
            location: data['location'] ?? '',
            openingTime: data['openingTime'] ?? 0,
            closingTime: data['closingTime'] ?? 0,
          );
        }).toList();

        if (restaurants.isEmpty) {
          return const Center(child: Text('No favorites yet'));
        }

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
                        UserRestaurantDetailPage(restaurant: restaurant),
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
                            if ((restaurant.offer ?? '').isNotEmpty)
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
                        child: restaurant.imageUrl.startsWith('data:image')
                            ? Image.memory(
                                decodeBase64Image(restaurant.imageUrl),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                restaurant.imageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'images/default.png',
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
