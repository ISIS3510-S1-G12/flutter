import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moviles/viewmodels/offer_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moviles/viewmodels/offer_viewmodel.dart';
import 'package:moviles/repositories/offer_repository.dart';
import 'package:moviles/models/offer.dart';

class UserOfertasPage extends StatefulWidget {
  const UserOfertasPage({super.key});

  @override
  State<UserOfertasPage> createState() => _UserOfertasPageState();
}

class _UserOfertasPageState extends State<UserOfertasPage> {
  String selectedFilter = "All"; // 🔹 Default filtro

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OfferViewModel(OfferRepository()),
      child: Consumer<OfferViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Ofertas"),
              backgroundColor: const Color.fromARGB(255, 121, 39, 101),
              actions: [
                DropdownButton<String>(
                  value: selectedFilter,
                  dropdownColor: Colors.white,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: "All", child: Text("All")),
                    DropdownMenuItem(value: "Today", child: Text("Today")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedFilter = value!;
                    });
                  },
                ),
              ],
            ),
            body: StreamBuilder<List<Offer>>(
              stream: vm.getOffers(""), // "" porque queremos todas las ofertas
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                var offers = snapshot.data ?? [];

                // 🔹 Filtrar según "Today"
                if (selectedFilter == "Today") {
                  final today = DateTime.now();
                  offers = offers.where((offer) {
                    final from = offer.validFrom;
                    final to = offer.validTo;
                    if (from == null || to == null) return false;
                    return today.isAfter(from) && today.isBefore(to);
                  }).toList();
                }

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
                        leading: (offer.image != null && offer.image!.isNotEmpty)
                            ? Image.network(
                                offer.image!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                'images/default.png',
                                width: 60,
                                height: 60,
                              ),
                        title: Text(offer.title),
                        subtitle: Text(offer.description),
                        trailing: Text(
                          "-${offer.discountPercentage.toStringAsFixed(0)}%",
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
