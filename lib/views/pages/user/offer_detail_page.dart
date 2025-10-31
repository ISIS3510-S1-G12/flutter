import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/offer.dart';
import '../../../viewmodels/offer_viewmodel.dart';

class OfferDetailPage extends StatefulWidget {
  final String offerId; // 👈 Solo pasamos el ID

  const OfferDetailPage({super.key, required this.offerId});

  @override
  State<OfferDetailPage> createState() => _OfferDetailPageState();
}

class _OfferDetailPageState extends State<OfferDetailPage> {
  String? restaurantName;
  bool _loadingRestaurant = true;

  @override
  void initState() {
    super.initState();
    // 🔹 Cargamos el detalle usando el ViewModel (con LruCache)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final offerVM = context.read<OfferViewModel>();
      await offerVM.loadOfferDetail(widget.offerId);
      _loadRestaurantName();
    });
  }

  Future<void> _loadRestaurantName() async {
    try {
      final offer = context.read<OfferViewModel>().selectedOffer;
      if (offer == null) return;

      final restaurantId = offer.restaurant_id.trim();
      final restaurantDoc = await FirebaseFirestore.instance
          .collection('Restaurants')
          .doc(restaurantId)
          .get();

      setState(() {
        restaurantName = restaurantDoc.data()?['name'] ?? 'Unknown';
        _loadingRestaurant = false;
      });
    } catch (e) {
      setState(() {
        restaurantName = 'Error loading name';
        _loadingRestaurant = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OfferViewModel>(
      builder: (context, offerVM, _) {
        final offer = offerVM.selectedOffer;

        if (offerVM.isLoading || offer == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(offer.title),
            backgroundColor: const Color.fromARGB(255, 214, 145, 104),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (offer.image != null && offer.image!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      offer.image!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 20),

                // 🏪 Nombre del restaurante
                _loadingRestaurant
                    ? const CircularProgressIndicator()
                    : Text(
                        "Restaurant: ${restaurantName ?? 'Unknown'}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),

                const SizedBox(height: 12),
                Text(
                  offer.description,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Price: \$${offer.price.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      "Discount: ${offer.discount_percentage.toStringAsFixed(0)}%",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (offer.valid_from != null && offer.valid_to != null)
                  Text(
                    "Valid: ${offer.valid_from!.toLocal().toString().split(' ')[0]} - "
                    "${offer.valid_to!.toLocal().toString().split(' ')[0]}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),

                const SizedBox(height: 20),
                if (offer.tags != null && offer.tags!.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: offer.tags!
                        .map((tag) => Chip(
                              label: Text(tag),
                              backgroundColor:
                                  const Color.fromARGB(255, 214, 145, 104)
                                      .withOpacity(0.2),
                            ))
                        .toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
