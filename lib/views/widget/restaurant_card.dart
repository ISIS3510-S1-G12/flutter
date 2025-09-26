import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:moviles/models/restaurant.dart';

class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantCard({super.key, required this.restaurant});
  

  // Función para decodificar Base64
  Uint8List decodeBase64Image(String base64String) {
    final base64Data = base64String.split(',').last; // Quita prefijo data:image
    return base64Decode(base64Data);
  }

  @override
  Widget build(BuildContext context) {
     // Verifica el valor de typeOfFood
  print('Restaurant: ${restaurant.name}, typeOfFood: ${restaurant.typeOfFood}');
  print('Restaurant: ${restaurant.name}, rating: ${restaurant.rating}');
  print('Restaurant: ${restaurant.name}, imageUrl: ${restaurant.imageUrl}');
  print('Restaurant: ${restaurant.name}, offer: ${restaurant.offer}');
  print('Restaurant: ${restaurant.name}, location: ${restaurant.location}');
  print('Restaurant: ${restaurant.name}, address: ${restaurant.address}');
  
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Columna de información
            Expanded(
              flex: 2, // más espacio para texto
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estrellas
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
                  // Nombre del restaurante
                  Text(
                    restaurant.name,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Tipo de comida
                  Text(
                    "Type of food: ${restaurant.typeOfFood}",
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Oferta (si existe)
                  if (restaurant.offer != null && restaurant.offer!.isNotEmpty)
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
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Imagen del restaurante
            Expanded(
              flex: 1,
              child: ClipRRect(
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
                            errorBuilder:
                                (context, error, stackTrace) => Image.asset(
                              'images/default.png',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ))
                    : Image.asset(
                        'images/default.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
