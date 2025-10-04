import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 👈 Necesario para obtener uid
import '../../../models/offer.dart';
import '../../../repositories/offer_repository.dart';
import '../../../viewmodels/offer_viewmodel.dart';
import '../../../viewmodels/user_viewmodel.dart';

class UserOfertasPage extends StatefulWidget {
  final String? restaurantId; // opcional

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
    // 🚀 Cargar automáticamente el usuario autenticado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userVM = Provider.of<UserViewModel>(context, listen: false);
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        print("DEBUG: Cargando usuario con uid -> $uid");
        userVM.loadUser(uid);
      } else {
        print("DEBUG: No hay usuario logueado en FirebaseAuth");
      }
    });
  }

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
                // Barra de búsqueda
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

                // Listado de Ofertas
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

                      // Filtro búsqueda
                      if (_searchQuery.isNotEmpty) {
                        offers = offers.where((o) {
                          final title = o.title.toLowerCase();
                          final desc = o.description.toLowerCase();
                          return title.contains(_searchQuery) ||
                              desc.contains(_searchQuery);
                        }).toList();
                      }

                      // Filtro Today
                      if (_filter == "Today") {
                        final today = DateTime.now();
                        offers = offers.where((o) {
                          return o.valid_from != null &&
                              o.valid_to != null &&
                              today.isAfter(o.valid_from!) &&
                              today.isBefore(o.valid_to!);
                        }).toList();
                      }

                      // DEBUG: Verificar usuario y budget
                      final userVM =
                          Provider.of<UserViewModel>(context, listen: false);
                      final user = userVM.currentUser;
                      final budget = userVM.getBudget();

                      print("DEBUG: Entró al build de ofertas");
                      print("DEBUG: Usuario actual -> $user");
                      print("DEBUG: Budget obtenido -> $budget");

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

                        print(
                            "DEBUG: Hoy hay ${todayOffers.length} ofertas activas");

                        if (todayOffers.isNotEmpty) {
                          final withinBudget = todayOffers.where(
                            (o) => o.price <= budget,
                          ).toList();

                          print(
                              "DEBUG: Ofertas dentro del budget -> ${withinBudget.length}");

                          final percentage =
                              (withinBudget.length / todayOffers.length) * 100;

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              _dialogShown = true;
                              print("DEBUG: Mostrando AlertDialog...");
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    title: const Text("Budget Insight"),
                                    content: Text(
                                      "${percentage.toStringAsFixed(0)}% of today’s offers fit your budget",
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
                        } else {
                          print("DEBUG: No hay ofertas activas hoy.");
                        }
                      }

                      // No hay ofertas
                      if (offers.isEmpty) {
                        return const Center(
                          child: Text("There are no offers available."),
                        );
                      }

                      // Lista
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
                                        "Discount: ${offer.discount_percentage.toStringAsFixed(0)}%",
                                        style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      if (offer.valid_from != null &&
                                          offer.valid_to != null)
                                        Text(
                                          "Valid: ${offer.valid_from!.toLocal().toString().split(' ')[0]} - ${offer.valid_to!.toLocal().toString().split(' ')[0]}",
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

  // BottomSheet de filtros
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
