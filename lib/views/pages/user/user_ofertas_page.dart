import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/restaurant.dart';

class UserOfertasPage extends StatelessWidget {
  const UserOfertasPage({super.key});

  Future<List<Restaurant>> fetchRestaurants() async {
    final snapshot = await FirebaseFirestore.instance.collection('Restaurants').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Restaurant(
        id: doc.id,
        name: data['name'] ?? '',
        typeOfFood: data['typeOfFood'] ?? '',
        rating: (data['rating'] != null)
            ? double.tryParse(data['rating'].toString()) ?? 0.0
            : 0.0,
        imageUrl: data['imageUrl'] ?? '',
        address: data['address'] ?? '',
        email: data['email'] ?? '',
        openingTime: data['openingTime'] ?? 0,
        closingTime: data['closingTime'] ?? 0,
        offer: data['offer'] == true, 
      );
    }).toList();
  }

  Uint8List decodeBase64Image(String base64String) {
    final base64Data = base64String.split(',').last;
    return base64Decode(base64Data);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Restaurant>>(
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
                      urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: 'com.example.moviles',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 🔹 Lista de ofertas
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: restaurants.length,
                itemBuilder: (context, index) {
                  final restaurant = restaurants[index];
                  return Card(
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
                                // Nombre del restaurante
                                Text(
                                  restaurant.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Oferta
                                if (restaurant.offer) // ✅ solo si es true
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      "Offer available 🎉",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      "No offers",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Imagen
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: restaurant.imageUrl.isNotEmpty
                                ? (restaurant.imageUrl.startsWith('data:image')
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
                                      ))
                                : Image.asset(
                                    'images/default.png',
                                    width: 80,
                                    height: 80,
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
    );
  }
}
