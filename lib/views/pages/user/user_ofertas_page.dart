import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'package:cached_network_image/cached_network_image.dart';

import '../../../models/offer.dart';
import '../../../repositories/offer_repository.dart';
import '../../../viewmodels/offer_viewmodel.dart';
import '../../../viewmodels/user_viewmodel.dart';
import '../../../viewmodels/visit_viewmodel.dart';
import '../../../services/connectivity_service.dart'; // 👈 usamos este
import 'offer_detail_page.dart';

class UserOfertasPage extends StatefulWidget {
  final String? restaurantId;

  const UserOfertasPage({super.key, this.restaurantId});

  @override
  State<UserOfertasPage> createState() => _UserOfertasPageState();
}

class _UserOfertasPageState extends State<UserOfertasPage> {
  String _filter = "All";
  String _searchQuery = "";
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();

    // 👤 Cargar usuario autenticado
    final authUser = fbAuth.FirebaseAuth.instance.currentUser;
    if (authUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<UserViewModel>().loadUser(authUser.uid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = context.watch<ConnectivityService>();
    final hasConnection = connectivity.hasConnection;

    // 🚨 Mostrar alert dialogs segun conexión
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!hasConnection && !connectivity.dialogShown) {
        connectivity.setDialogShown(true);
        _showNoConnectionDialog(connectivity);
      } else if (hasConnection && connectivity.dialogShown) {
        connectivity.setDialogShown(false);
        _showReconnectedDialog();
      }
    });

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
                // 🔍 Buscador y filtro
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
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

                // 📋 Lista de ofertas
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

                      // 🔍 Filtro de búsqueda
                      if (_searchQuery.isNotEmpty) {
                        offers = offers.where((o) {
                          final title = o.title.toLowerCase();
                          final desc = o.description.toLowerCase();
                          return title.contains(_searchQuery) ||
                              desc.contains(_searchQuery);
                        }).toList();
                      }

                      // 📅 Filtro "Today"
                      if (_filter == "Today") {
                        final today = DateTime.now();
                        offers = offers.where((o) {
                          return o.valid_from != null &&
                              o.valid_to != null &&
                              today.isAfter(o.valid_from!) &&
                              today.isBefore(o.valid_to!);
                        }).toList();
                      }

                      // 💰 Mostrar diálogo de presupuesto
                      final userVM =
                          Provider.of<UserViewModel>(context, listen: false);
                      final user = userVM.currentUser;
                      final budget = userVM.getBudget();

                      if (!_dialogShown &&
                          user != null &&
                          budget != null &&
                          offers.isNotEmpty) {
                        final today = DateTime.now();
                        final todayOffers = offers.where((o) {
                          return o.valid_from != null &&
                              o.valid_to != null &&
                              today.isAfter(o.valid_from!) &&
                              today.isBefore(o.valid_to!);
                        }).toList();

                        if (todayOffers.isNotEmpty) {
                          final withinBudget = todayOffers
                              .where((o) => o.price <= budget)
                              .toList();

                          final percentage = (withinBudget.length /
                                  todayOffers.length) *
                              100;

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              _dialogShown = true;
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    title: const Text(
                                        "Offers and Budget Insight"),
                                    content: Text(
                                      "${percentage.toStringAsFixed(0)}% of today’s offers fit within your budget.",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context),
                                        child: const Text("OK"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                          });
                        }
                      }

                      if (offers.isEmpty) {
                        return const Center(
                          child: Text("There are no offers available."),
                        );
                      }

                      //  Lista de ofertas
                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: offers.length,
                        itemBuilder: (context, index) {
                          final offer = offers[index];
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      OfferDetailPage(offerId: offer.id!),
                                ),
                              );
                            },
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  if (offer.image != null &&
                                      offer.image!.isNotEmpty)
                                    ClipRRect(
                                      borderRadius:
                                          const BorderRadius.vertical(
                                              top: Radius.circular(12)),
                                      child: CachedNetworkImage(
                                        imageUrl: offer.image!,
                                        height: 160,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            const Center(
                                                child:
                                                    CircularProgressIndicator()),
                                        errorWidget:
                                            (context, url, error) {
                                          if (!connectivity.dialogShown &&
                                              !hasConnection) {
                                            connectivity
                                                .setDialogShown(true);
                                            _showNoConnectionDialog(
                                                connectivity);
                                          }
                                          return const Center(
                                            child: Icon(Icons.cloud_off,
                                                size: 70,
                                                color: Colors.grey),
                                          );
                                        },
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          offer.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(offer.description),
                                        const SizedBox(height: 8),
                                        Text(
                                          "Discount: ${offer.discount_percentage.toStringAsFixed(0)}%",
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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

  // 🚫 Sin conexión
  void _showNoConnectionDialog(ConnectivityService connectivity) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_off, color: Colors.grey),
            SizedBox(width: 8),
            Text("Connection Error",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Unable to display all offers because there is no internet connection.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // 🌐 Conexión restaurada
  void _showReconnectedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi, color: Colors.green),
            SizedBox(width: 8),
            Text("Connection Restored",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text("Your connection is back online."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ⚙️ Filtros (All / Today)
  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.list),
                title: const Text("All offers"),
                onTap: () {
                  setState(() => _filter = "All");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.today),
                title: const Text("Today only"),
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
