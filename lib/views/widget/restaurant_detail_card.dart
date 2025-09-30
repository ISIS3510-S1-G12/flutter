import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '/models/restaurant.dart';

class RestaurantDetailCard extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantDetailCard({super.key, required this.restaurant});

  Uint8List decodeBase64Image(String base64String) {
    final base64Data = base64String.split(',').last;
    return base64Decode(base64Data);
  }

  String formatTime(int time) {
    if (time < 0 || time > 2359) return "--:--";
    final hour = (time ~/ 100).toString().padLeft(2, '0');
    final minute = (time % 100).toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del restaurante
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: restaurant.imageUrl.isNotEmpty
                  ? (restaurant.imageUrl.startsWith('data:image')
                      ? Image.memory(
                          decodeBase64Image(restaurant.imageUrl),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          restaurant.imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
                            'images/default.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ))
                  : Image.asset(
                      'images/default.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(width: 16),
            // Información del restaurante
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre
                  Text(
                    restaurant.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  // Tipo de comida
                  Text(
                    "Type: ${restaurant.typeOfFood}",
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  // Rating
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
                  const SizedBox(height: 8),
                  // Dirección
                  Text(
                    "Address: ${restaurant.address}",
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  // Horarios
                  Text(
                    "Opens: ${formatTime(restaurant.openingTime)} - Closes: ${formatTime(restaurant.closingTime)}",
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  // Oferta (bool → mensaje)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: restaurant.offer
                          ? Colors.green[100]
                          : Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      restaurant.offer
                          ? "Offer available"
                          : "No offers",
                      style: TextStyle(
                        fontSize: 12,
                        color: restaurant.offer ? Colors.green : Colors.red,
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
