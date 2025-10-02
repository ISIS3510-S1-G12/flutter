import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/offer.dart';
import '../../../repositories/offer_repository.dart';
import '../../../viewmodels/offer_viewmodel.dart';

class UserOfertasPage extends StatefulWidget {
  final String? restaurantId; // opcional

  const UserOfertasPage({super.key, this.restaurantId});

  @override
  State<UserOfertasPage> createState() => _UserOfertasPageState();
}

class _UserOfertasPageState extends State<UserOfertasPage> {
  String _filter = "All"; // All | Today
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OfferViewModel(OfferRepository()),
      child: Consumer<OfferViewModel>(
        builder: (context, offerVM, _) {
          final stream = widget.restaurantId != null
              ? offerVM.getOffersByRestaurant(widget.restaurantId!)
              : offerVM.getAllOffers();

          return Scaffold(
            backgroundColor: Colors.white,
            body: Column(
              children: [
                // 🔹 SearchBar + Botón de filtro
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      // Barra de búsqueda
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Buscar ofertas...",
                            hintStyle: const TextStyle(color: Colors.white),
                            prefixIcon:
                                const Icon(Icons.search, color: Colors.white),
                            filled: true,
                            fillColor:
                                const Color.fromARGB(255, 214, 145, 104),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (query) {
                            setState(() {
                              _searchQuery = query.toLowerCase();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Botón de filtro
                      Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 214, 145, 104),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.filter_list,
                              color: Colors.white),
                          onPressed: () {
                            _showFilterOptions(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // 🔹 Lista de ofertas
                Expanded(
                  child: StreamBuilder<List<Offer>>(
                    stream: stream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                            child: Text("Error: ${snapshot.error}"));
                      }

                      var offers = snapshot.data ?? [];

                      // Filtro por búsqueda
                      if (_searchQuery.isNotEmpty) {
                        offers = offers.where((o) {
                          final title = o.title.toLowerCase();
                          final desc = o.description.toLowerCase();
                          return title.contains(_searchQuery) ||
                              desc.contains(_searchQuery);
                        }).toList();
                      }

                      // Filtro por fecha "Hoy"
                      if (_filter == "Today") {
                        final today = DateTime.now();
                        offers = offers.where((o) {
                          return o.validFrom != null &&
                              o.validTo != null &&
                              today.isAfter(o.validFrom!) &&
                              today.isBefore(o.validTo!);
                        }).toList();
                      }

                      if (offers.isEmpty) {
                        return const Center(
                          child: Text("No hay ofertas disponibles."),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: offers.length,
                        itemBuilder: (context, index) {
                          final offer = offers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (offer.image != null &&
                                    offer.image!.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12)),
                                    child: Image.network(
                                      offer.image!,
                                      height: 160,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(offer.title,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      Text(offer.description),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Descuento: ${offer.discountPercentage.toStringAsFixed(0)}%",
                                        style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      if (offer.validFrom != null &&
                                          offer.validTo != null)
                                        Text(
                                          "Válido: ${offer.validFrom!.toLocal().toString().split(' ')[0]} - ${offer.validTo!.toLocal().toString().split(' ')[0]}",
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 🔹 Función para mostrar filtros en un BottomSheet
  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.list),
                title: const Text("Todas las ofertas"),
                onTap: () {
                  setState(() => _filter = "All");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.today),
                title: const Text("Solo las de hoy"),
                onTap: () {
                  setState(() => _filter = "Today");
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
