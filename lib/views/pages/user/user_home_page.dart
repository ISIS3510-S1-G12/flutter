import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'package:moviles/viewmodels/restaurant_viewmodel.dart';
import 'package:moviles/views/widget/restaurant_card.dart';
import 'package:moviles/views/pages/user/user_favorites_page.dart';
import 'package:moviles/views/pages/user/user_restaurant_detail_page.dart';
import 'package:moviles/views/pages/user/user_ofertas_page.dart';
import 'package:moviles/views/pages/user/user_review_history.dart';
import 'package:moviles/viewmodels/visit_viewmodel.dart';
import 'package:geocoding/geocoding.dart';


class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> with SingleTickerProviderStateMixin {
  final FirebaseInAppMessaging fiam = FirebaseInAppMessaging.instance;
  List<LatLng> restaurantLocations = [];
  late TabController _tabController;
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;



  @override
  void initState() {
    super.initState();
_tabController = TabController(length: 4, vsync: this);

_tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final currentIndex = _tabController.index;
        analytics.logEvent(name: "tab_changed", parameters: {
          "index": currentIndex,
        });
        print("Tab changed to index: $currentIndex");
      }
    });


    fiam.setMessagesSuppressed(false);

    _triggerMealEvent();

  Future<void> _loadRestaurantLocations(RestaurantViewModel vm) async {
    final List<LatLng> coords = [];

    for (final r in vm.filteredRestaurants) {
      try {
        print("Dirección del restaurante: ${r.address}");
        if (r.address != null && r.address!.isNotEmpty) {
          final locations = await locationFromAddress(r.address!);
          if (locations.isNotEmpty) {
            final loc = locations.first;
            coords.add(LatLng(loc.latitude, loc.longitude));
          }
        }
      } catch (e) {
        print("Error al geocodificar ${r.address}: $e");
      }
    }

    setState(() {
      restaurantLocations = coords;
    });
  }

  // 🔹 Cargar restaurantes
  Future.microtask(() async {
    final vm = context.read<RestaurantViewModel>();
    await vm.fetchRestaurants();
    await _loadRestaurantLocations(vm);
    });
        
  
    // 🔹 Mostrar AlertDialog a los 10 segundos
    Future.delayed(const Duration(seconds: 10), () async {
      if (!mounted) return;

      final visitVM = context.read<VisitViewModel>();
      await visitVM.loadDaysSinceLastVisitGlobal();

      if (!mounted) return;

      int? days = visitVM.daysSinceLastVisitGlobal;
      String message;

      if (days == null) {
        message = "You have not visited any restaurant yet.";
      } else if (days == 0) {
        message = "You visited a restaurant today.";
      } else if (days == 1) {
        message = "It’s been 1 day since your last restaurant visit.";
      } else {
        message = "It’s been $days days since your last restaurant visit.";
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Last visit"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    });
  }

  void _triggerMealEvent() {
    final now = DateTime.now();
    final hour = now.hour;

    print("Hora actual: ${now.hour}:${now.minute}");

    if (hour >= 5 && hour < 12) {
      fiam.triggerEvent('breakfast_time');
    } else if (hour >= 12 && hour < 18) {
      fiam.triggerEvent('lunch_time');
    } else if (hour >= 18 && hour < 22) {
      fiam.triggerEvent('dinner_time');
    } else {
      print("ℹ No se disparó ningún evento (${now.hour}:${now.minute})");
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                "images/483891256-e6bd4888-8904-4028-911f-dff62cc98965.png",
                height: MediaQuery.of(context).size.height * 0.08,
              ),
              InkWell(
                onTap: () {},
                child: const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color.fromARGB(255, 214, 145, 104),
                  child: Icon(Icons.person, color: Colors.white),
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(70),
            child: Column(
              children: [
                Divider(color: Colors.black, thickness: 1),
                TabBar(
                  controller: _tabController,
                  tabAlignment: TabAlignment.fill,
                  isScrollable: false,
                  labelColor: Colors.black,
                  indicatorColor: Color.fromARGB(255, 214, 145, 104),
                  tabs: [
                    Tab(text: "Home"),
                    Tab(text: "Favorites"),
                    Tab(text: "Offers"),
                    Tab(text: "History review"),
                  ],
                ),
                Divider(color: Colors.black, thickness: 1),
              ],
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            Consumer<RestaurantViewModel>(
              builder: (context, vm, child) {
                if (vm.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (vm.errorMessage != null) {
                  return Center(child: Text("Error: ${vm.errorMessage}"));
                }

                final restaurants = vm.filteredRestaurants;

                return Column(
                  children: [
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: "Search here...",
                                hintStyle:
                                    const TextStyle(color: Colors.white),
                                prefixIcon: const Icon(Icons.search,
                                    color: Colors.white),
                                filled: true,
                                fillColor:
                                    const Color.fromARGB(255, 214, 145, 104),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (query) {
                                if (query.isEmpty) {
                                  vm.clearFilter();
                                } else {
                                  vm.applyFilter(FilterByType(query));
                                }
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
                                _showFilterOptions(context, vm);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            decoration: const BoxDecoration(
                              color: Color.fromARGB(255, 214, 145, 104),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.chat, color: Colors.white),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 🔹 Banner del restaurante más visitado de la semana
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: FutureBuilder<Map<String, int>>(
    future: context.read<VisitViewModel>().getWeeklyVisitCounts(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const SizedBox();
      final visitCounts = snapshot.data!;
      if (visitCounts.isEmpty) return const SizedBox();

      // Encuentra el restaurante con más visitas
      final mostVisited = visitCounts.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );

      final topRestaurantId = mostVisited.key;

      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("Restaurants")
            .doc(topRestaurantId)
            .get(),
        builder: (context, restaurantSnap) {
          if (!restaurantSnap.hasData || !restaurantSnap.data!.exists) {
            return const SizedBox();
          }

          final restaurantData =
              restaurantSnap.data!.data() as Map<String, dynamic>;

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "🏆 ${restaurantData['name']} is the restaurant most visited this week.",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
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

                    Container(
                      height: 200,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FlutterMap(
  options: MapOptions(
    initialCenter: LatLng(4.65, -74.08), // Bogotá por defecto
    initialZoom: 12.0,
    maxZoom: 18.0,
    onTap: (tapPosition, latLng) {
      print("Tapped at: $latLng");
      print("Direcciones de restaurants: ${vm.filteredRestaurants.map((r) => r.address).join(' otro ')}");
      print("Coordenadas de restaurants: $restaurantLocations");
    },
  ),
  children: [
    TileLayer(
      urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
      userAgentPackageName: 'com.example.moviles',
    ),
    MarkerLayer(
      markers: [
        for (int i = 0; i < vm.filteredRestaurants.length; i++)
          if (i < restaurantLocations.length)
            Marker(
              width: 40,
              height: 40,
              point: restaurantLocations[i],
              child: GestureDetector(
                onTap: () {
                  final restaurant = vm.filteredRestaurants[i];
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          UserRestaurantDetailPage(restaurant: restaurant),
                    ),
                  );
                },
                child: const Icon(
                  Icons.location_pin,
                  color: Color.fromARGB(255, 170, 98, 153),
                  size: 40,
                ),
              ),
            ),
      ],
    ),

  ],
),

                      ),
                    ),

                    
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: restaurants.length,
                        itemBuilder: (context, index) {
                          final restaurant = restaurants[index];
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      UserRestaurantDetailPage(
                                          restaurant: restaurant),
                                ),
                              );
                            },
                            child: RestaurantCard(restaurant: restaurant),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            const UserFavoritesPage(),
            const UserOfertasPage(),
            const UserReviewHistoryPage(),
          ],
        ),
      );
  }

  void _showFilterOptions(BuildContext context, RestaurantViewModel vm) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.local_offer),
            title: const Text("Con oferta"),
            onTap: () {
              vm.applyFilter(FilterWithOffer());
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text("Sin oferta"),
            onTap: () {
              vm.applyFilter(FilterWithoutOffer());
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.clear),
            title: const Text("Quitar filtros"),
            onTap: () {
              vm.clearFilter();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
