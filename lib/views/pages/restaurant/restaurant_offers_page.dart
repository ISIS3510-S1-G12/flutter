import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moviles/viewmodels/offer_viewmodel.dart';
import 'package:moviles/views/pages/restaurant/offer_form_page.dart';
import 'package:moviles/models/offer.dart';
import 'package:moviles/repositories/offer_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class RestaurantOffersPage extends StatefulWidget {
  final String restaurantId;

  const RestaurantOffersPage({super.key, required this.restaurantId});

  @override
  State<RestaurantOffersPage> createState() => _RestaurantOffersPageState();
}

class _RestaurantOffersPageState extends State<RestaurantOffersPage> {
  final OfferRepository _offerRepo = OfferRepository();

  bool _isOnline = true;
  final Connectivity _connectivity = Connectivity(); //  inicializado aquí

  @override
  void initState() {
    super.initState();
    _listenToConnectivity(); //  empieza a escuchar
    _syncLocalOffers();
  }

  void _listenToConnectivity() {
    _connectivity.onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });

      if (_isOnline && !wasOnline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Connection restored. Syncing offers..."),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        _syncLocalOffers();
      } else if (!_isOnline && wasOnline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You're offline. Changes will be saved locally."),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Future<void> _syncLocalOffers() async {
    try {
      await _offerRepo.syncOffers();
      print(" Local offers synced automatically");
    } catch (e) {
      print("Error syncing offers: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final offerVM = Provider.of<OfferViewModel>(context);

    return Scaffold(
      body: StreamBuilder<List<Offer>>(
        stream: offerVM.getOffers(widget.restaurantId),
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
                    "${offer.description}\n${offer.discount_percentage}% OFF",
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
          if (!_isOnline) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Offline mode"),
                content: const Text(
                    "You are currently offline. Please connect to the internet to create a new offer."),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"),
                  ),
                ],
              ),
            );
            return;
          }

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OfferFormPage(restaurantId: widget.restaurantId),
            ),
          );
          if (result == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Offer created successfully")),
            );
          }
        },
      ),
    );
  }
}
