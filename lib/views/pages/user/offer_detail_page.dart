import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/connectivity_service.dart';
import '../../../models/offer.dart'; // Asegúrate de importar tu modelo Offer

class OfferDetailPage extends StatefulWidget {
  final String offerId;

  const OfferDetailPage({super.key, required this.offerId});

  @override
  State<OfferDetailPage> createState() => _OfferDetailPageState();
}

class _OfferDetailPageState extends State<OfferDetailPage> {
  bool _isDialogOpen = false;
  String? _imageKey;

  @override
  void initState() {
    super.initState();
    _imageKey = DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<Map<String, dynamic>> _loadOfferAndRestaurant() async {
    // 1️⃣ Cargar la oferta desde Firestore
    final offerDoc = await FirebaseFirestore.instance
        .collection('Offers')
        .doc(widget.offerId)
        .get();

    if (!offerDoc.exists) {
      throw Exception("Offer not found");
    }

    final offerData = offerDoc.data()!;
    final offer = Offer.fromMap(offerData, offerDoc.id);

    // 2️⃣ Cargar el restaurante relacionado
    final restaurantDoc = await FirebaseFirestore.instance
        .collection('Restaurants')
        .doc(offer.restaurant_id.trim())
        .get();

    final restaurantName = restaurantDoc.data()?['name'] ?? 'Unknown';

    return {
      'offer': offer,
      'restaurantName': restaurantName,
    };
  }

  void _showNoConnectionDialog(ConnectivityService connection) {
    if (_isDialogOpen || connection.dialogShown) return;

    _isDialogOpen = true;
    connection.setDialogShown(true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_off, color: Colors.grey),
            SizedBox(width: 8),
            Text("Connection Error",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Unable to display this offer because there is no internet connection.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _isDialogOpen = false;
              connection.setDialogShown(false);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connection = ConnectivityService(); // o context.watch<ConnectivityService>();
    final hasConnection = connection.hasConnection;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!hasConnection) {
        _showNoConnectionDialog(connection);
      } else if (hasConnection && _isDialogOpen) {
        Navigator.of(context, rootNavigator: true).maybePop();
        _isDialogOpen = false;
        connection.setDialogShown(false);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Offer Detail"),
        backgroundColor: const Color.fromARGB(255, 214, 145, 104),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadOfferAndRestaurant(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text("Error loading offer: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("Offer not found"));
          }

          final offer = snapshot.data!['offer'] as Offer;
          final restaurantName = snapshot.data!['restaurantName'] as String;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (offer.image != null && offer.image!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      offer.image!,
                      key: ValueKey(_imageKey),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        if (!hasConnection) {
                          _showNoConnectionDialog(connection);
                        }
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_off,
                                  size: 70, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                  "Image unavailable — no connection and not cached"),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 20),

                Text(
                  "Restaurant: $restaurantName",
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
                      style: const TextStyle(fontSize: 16),
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
                    style:
                        const TextStyle(fontSize: 14, color: Colors.grey),
                  ),

                const SizedBox(height: 20),

                if (offer.tags != null && offer.tags!.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: offer.tags!
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            backgroundColor:
                                const Color.fromARGB(255, 214, 145, 104)
                                    .withOpacity(0.2),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
