import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';
import 'package:moviles/viewmodels/restaurant_viewmodel.dart';
import 'package:moviles/views/widget/restaurant_card.dart';
import 'package:moviles/views/pages/user/user_favorites_page.dart';
import 'package:moviles/views/pages/user/user_restaurant_detail_page.dart';
import 'package:moviles/views/pages/user/user_ofertas_page.dart';
import 'package:moviles/views/pages/user/user_review_history.dart';
import 'package:moviles/viewmodels/visit_viewmodel.dart';
import 'package:moviles/views/pages/user/user_loyalty_ranking_page.dart';
import 'package:moviles/models/restaurant.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage>
    with SingleTickerProviderStateMixin {
  final FirebaseInAppMessaging fiam = FirebaseInAppMessaging.instance;
  List<LatLng> restaurantLocations = [];
  late TabController _tabController;
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  // variable para el último restaurante
  Restaurant? lastVisitedRestaurant;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        analytics.logEvent(name: "tab_changed", parameters: {
          "index": _tabController.index,
        });
      }
    });

    fiam.setMessagesSuppressed(false);
    _triggerMealEvent();

    // función local para geocodificar la lista actual de restaurantes
    Future<void> _loadRestaurantLocations(RestaurantViewModel vm) async {
      final List<LatLng> coords = [];

      for (final r in vm.filteredRestaurants) {
        try {
          if (r.address != null && r.address!.isNotEmpty) {
            final locations = await locationFromAddress(r.address!);
            if (locations.isNotEmpty) {
              final loc = locations.first;
              coords.add(LatLng(loc.latitude, loc.longitude));
            }
          }
        } catch (e) {
          // no bloquear UI por errores de geocoding
          debugPrint("Error al geocodificar ${r.address}: $e");
        }
      }

      if (mounted) {
        setState(() {
          restaurantLocations = coords;
        });
      }
    }

    // Cargar restaurantes y posiciones (cache then network)
    Future.microtask(() async {
      final vm = context.read<RestaurantViewModel>();

      // 1) intentar cargar cache local (SharedPreferences) primero
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedData = prefs.getString('cached_restaurants');
        if (cachedData != null) {
          final decoded = json.decode(cachedData) as List;
          final cachedRestaurants =
              decoded.map((r) => Restaurant.fromMap(r)).toList();
          vm.restaurants = cachedRestaurants;
          vm.filteredRestaurants = cachedRestaurants;
          vm.notifyListeners();
        }
      } catch (e) {
        debugPrint("No cache available or failed to read cache: $e");
      }

      // 2) fetch from network and update cache + locations
      try {
        await vm.fetchRestaurants();
        final prefs = await SharedPreferences.getInstance();
        final encoded =
            json.encode(vm.restaurants.map((r) => r.toMap()).toList());
        await prefs.setString('cached_restaurants', encoded);
      } catch (e) {
        debugPrint("Error fetching restaurants from network: $e");
      }

      // 3) load geocoded locations and last visited
      await _loadRestaurantLocations(vm);
      await _loadLastVisitedRestaurant();
    });

    // AlertDialog con info de últimos días desde la vista de visitas (10s)
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

      if (mounted) {
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
      }
    });
  }

  // cargar último restaurante desde SharedPreferences
  Future<void> _loadLastVisitedRestaurant() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('last_restaurant_id');
      final name = prefs.getString('last_restaurant_name');
      if (id != null && name != null) {
        setState(() {
          lastVisitedRestaurant = Restaurant(
            id: id,
            name: name,
            email: '',
            address: '',
            typeOfFood: '',
            offer: false,
            imageUrl: '',
            openingTime: 9,
            closingTime: 22,
            busiestHours: {},
            rating: 0.0,
          );
        });
      }
    } catch (e) {
      debugPrint("Failed to load last visited restaurant: $e");
    }
  }

  // guardar restaurante cuando el usuario entra a su detalle
  Future<void> _saveLastVisited(Restaurant restaurant) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_restaurant_id', restaurant.id);
      await prefs.setString('last_restaurant_name', restaurant.name);
      setState(() {
        lastVisitedRestaurant = restaurant;
      });
    } catch (e) {
      debugPrint("Failed to save last visited: $e");
    }
  }

  void _triggerMealEvent() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 5 && hour < 12) {
      fiam.triggerEvent('breakfast_time');
    } else if (hour >= 12 && hour < 18) {
      fiam.triggerEvent('lunch_time');
    } else if (hour >= 18 && hour < 22) {
      fiam.triggerEvent('dinner_time');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildMap(ThemeData theme, RestaurantViewModel vm) {
    // fallback center si no hay ubicaciones geocodificadas
    final LatLng center =
        restaurantLocations.isNotEmpty ? restaurantLocations.first : LatLng(4.65, -74.08);

    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 12.0,
            maxZoom: 18.0,
            onTap: (tapPosition, latLng) {
              debugPrint("Tapped at: $latLng");
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
                          _saveLastVisited(restaurant); // guardo al abrir detalle
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          preferredSize: const Size.fromHeight(70),
          child: Column(
            children: [
              const Divider(color: Colors.black, thickness: 1),
              TabBar(
                controller: _tabController,
                tabAlignment: TabAlignment.fill,
                isScrollable: false,
                labelColor: Colors.black,
                indicatorColor: const Color.fromARGB(255, 214, 145, 104),
                tabs: const [
                  Tab(text: "Home"),
                  Tab(text: "Favorites"),
                  Tab(text: "Offers"),
                  Tab(text: "History review"),
                ],
              ),
              const Divider(color: Colors.black, thickness: 1),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Home Tab
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
                  // mostrar último restaurante si existe
                  if (lastVisitedRestaurant != null)
                    Card(
                      color: const Color.fromARGB(255, 240, 222, 214),
                      margin: const EdgeInsets.all(12),
                      child: ListTile(
                        leading: const Icon(Icons.history, color: Colors.teal),
                        title: Text(
                          "Last visited: ${lastVisitedRestaurant!.name}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  UserRestaurantDetailPage(restaurant: lastVisitedRestaurant!),
                            ),
                          );
                        },
                      ),
                    ),

                  // Botón ranking semanal
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 214, 145, 104),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.leaderboard),
                      label: const Text("View Weekly Loyalty Ranking"),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserLoyaltyRankingPage(),
                          ),
                        );
                      },
                    ),
                  ),

                  // Buscador + filtros
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Search here...",
                              hintStyle: const TextStyle(color: Colors.white),
                              prefixIcon:
                                  const Icon(Icons.search, color: Colors.white),
                              filled: true,
                              fillColor: const Color.fromARGB(255, 214, 145, 104),
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
                            icon: const Icon(Icons.filter_list, color: Colors.white),
                            onPressed: () => _showFilterOptions(context, vm),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Banner restaurante más visitado
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: FutureBuilder<Map<String, int>>(
                      future: context.read<VisitViewModel>().getWeeklyVisitCounts(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        final visitCounts = snapshot.data!;
                        if (visitCounts.isEmpty) return const SizedBox();

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
                            if (!restaurantSnap.hasData ||
                                !restaurantSnap.data!.exists) return const SizedBox();

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

                  // Mapa (open source tiles)
                  _buildMap(theme, vm),

                  // Lista restaurantes
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: restaurants.length,
                      itemBuilder: (context, index) {
                        final restaurant = restaurants[index];
                        return InkWell(
                          onTap: () async {
                            await _saveLastVisited(restaurant); // guardar último visitado
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    UserRestaurantDetailPage(restaurant: restaurant),
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

          // Tabs restantes
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
