import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moviles/viewmodels/offer_viewmodel.dart';
import 'package:moviles/views/pages/restaurant/offer_form_page.dart';
import 'package:moviles/models/offer.dart';

class RestaurantOffersPage extends StatelessWidget {
  final String restaurantId;

  const RestaurantOffersPage({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    //  Escucha cambios en OfferViewModel
    final offerVM = Provider.of<OfferViewModel>(context);

    return Scaffold(
 
      body: StreamBuilder<List<Offer>>(
        stream: offerVM.getOffers(restaurantId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No offers available"));
          }

          final offers = snapshot.data!;
          print("📲 Renderizando ${offers.length} ofertas");

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: (offer.image != null && offer.image!.isNotEmpty)
                      ? Image.network(
                          offer.image!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.local_offer, color: Colors.teal),
                  title: Text(offer.title),
                  subtitle: Text(
                    "${offer.description}\n${offer.discountPercentage}% OFF",
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 39, 111, 121),
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OfferFormPage(restaurantId: restaurantId),
            ),
          );
          if (result == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Offer created successfully")),
            );
          }
        },
      ),
    );
  }
}
