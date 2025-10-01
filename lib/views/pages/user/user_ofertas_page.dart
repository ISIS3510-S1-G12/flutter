import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserOfertasPage extends StatelessWidget {
  const UserOfertasPage({super.key});

  Future<List<Map<String, dynamic>>> fetchOffers() async {
    final snapshot = await FirebaseFirestore.instance.collection('Offers').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'title': data['title'] ?? '',
        'description': data['description'] ?? '',
        'restaurantId': data['restaurantId'] ?? '',
        'imageUrl': data['imageUrl'] ?? '',
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchOffers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final offers = snapshot.data ?? [];

        if (offers.isEmpty) {
          return const Center(child: Text('No hay ofertas disponibles'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: offers.length,
          itemBuilder: (context, index) {
            final offer = offers[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: offer['imageUrl'].isNotEmpty
                    ? Image.network(
                        offer['imageUrl'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        'images/default.png',
                        width: 60,
                        height: 60,
                      ),
                title: Text(offer['title']),
                subtitle: Text(offer['description']),
              ),
            );
          },
        );
      },
    );
  }
}
