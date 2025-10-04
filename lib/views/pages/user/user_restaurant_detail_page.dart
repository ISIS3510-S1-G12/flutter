// 📌 UserRestaurantDetailPage sin alert dialog en initState
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '/models/restaurant.dart';
import '/models/dish.dart';
import '/repositories/review_repository.dart';
import '/repositories/dish_repository.dart';
import '/repositories/visits_repository.dart';
import '/viewmodels/user_restaurant_detail_viewmodel.dart';
import '/viewmodels/review_viewmodel.dart';
import '/viewmodels/visit_viewmodel.dart';
import '/views/widget/restaurant_detail_card.dart';
import '/views/pages/user/write_review_page.dart';
import '/views/pages/user/user_ofertas_page.dart';
import 'package:flutter_map/flutter_map.dart';

class UserRestaurantDetailPage extends StatefulWidget {
  final Restaurant restaurant;
  const UserRestaurantDetailPage({super.key, required this.restaurant});

  @override
  State<UserRestaurantDetailPage> createState() => _UserRestaurantDetailPageState();
}

class _UserRestaurantDetailPageState extends State<UserRestaurantDetailPage> {
  @override
  void initState() {
    super.initState();
    // ❌ Ya no hay lógica de AlertDialog aquí
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = widget.restaurant;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              UserRestaurantDetailViewModel()..checkIfFavorite(restaurant),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              ReviewViewModel(ReviewRepository())..loadReviews(restaurant.id),
        ),
        ChangeNotifierProvider(
          create: (_) => VisitViewModel(VisitsRepository()),
        ),
      ],
      child: Consumer3<UserRestaurantDetailViewModel, ReviewViewModel,
          VisitViewModel>(
        builder: (context, vm, reviewVM, visitVM, _) {
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection("Restaurants")
                .doc(restaurant.id)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;

              final fullRestaurant = Restaurant(
                id: restaurant.id,
                name: data['name'] ?? '',
                typeOfFood: data['typeOfFood'] ?? '',
                rating: (data['rating'] != null)
                    ? double.tryParse(data['rating'].toString()) ?? 0.0
                    : 0.0,
                offer: data['offer'] == true,
                imageUrl: data['imageUrl'] ?? '',
                address: data['address'] ?? '',
                openingTime: data['openingTime'] ?? 0,
                closingTime: data['closingTime'] ?? 0,
                email: data['email'] ?? '',
              );
              return DefaultTabController(
                length: 3,
                child: Scaffold(
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
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Color.fromARGB(255, 214, 145, 104),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                      ],
                    ),
                    bottom: const TabBar(
                      labelColor: Colors.black,
                      indicatorColor: Color.fromARGB(255, 214, 145, 104),
                      tabs: [
                        Tab(text: "Menu"),
                        Tab(text: "Offers"),
                        Tab(text: "Reviews"),
                      ],
                    ),
                  ),
                  body: TabBarView(
                    children: [
                      // MENU TAB
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            RestaurantDetailCard(restaurant: fullRestaurant),

                            // 🔹 Botones Favorito + People arriba, Visited abajo
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Column(
                                children: [
                                  // fila con 2 botones
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              vm.toggleFavorite(fullRestaurant),
                                          icon: Icon(
                                            vm.isFavorite
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            "Favorite",
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color.fromARGB(
                                                    255, 121, 39, 101),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 6),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            int peopleCount =
                                                await vm.scanNearbyDevices();
                                            if (context.mounted) {
                                              showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                  title: const Text(
                                                      "People detected"),
                                                  content: Text(
                                                      "We detected $peopleCount nearby devices in this restaurant."),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context),
                                                      child: const Text("OK"),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }
                                          },
                                          icon: const Icon(
                                              Icons.bluetooth_searching,
                                              size: 18),
                                          label: const Text(
                                            "People",
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.teal,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 6),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // botón único abajo
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        await visitVM
                                            .registerVisit(restaurant.id);
                                        if (context.mounted) {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title:
                                                  const Text("Visit recorded"),
                                              content: const Text(
                                                  "Your visit has been recorded successfully."),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text("OK"),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.check_circle,
                                          size: 18),
                                      label: const Text(
                                        "Visited",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 🌍 Mapa
                            Container(
                              height: 200,
                              margin: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: FlutterMap(
                                  options: const MapOptions(maxZoom: 13.0),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                                      userAgentPackageName:
                                          'com.example.moviles',
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // DISHES
                            StreamBuilder<List<Dish>>(
                              stream: DishRepository()
                                  .getDishesByRestaurant(fullRestaurant.id),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }
                                final dishes = snapshot.data!;
                                if (dishes.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text("No dishes yet."),
                                  );
                                }
                                return Column(
                                  children: dishes.map((dish) {
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: ListTile(
                                        leading: dish.imageUrl.isNotEmpty
                                            ? Image.network(
                                                dish.imageUrl,
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                              )
                                            : const Icon(
                                                Icons.image_not_supported),
                                        title: Text(dish.name),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                "\$${dish.price.toStringAsFixed(2)}"),
                                            Row(
                                              children: List.generate(
                                                5,
                                                (i) => Icon(
                                                  i < dish.rating
                                                      ? Icons.star
                                                      : Icons.star_border,
                                                  color: Colors.amber,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // OFFERS TAB
                      UserOfertasPage(restaurantId: fullRestaurant.id),

                      // REVIEWS TAB
                      Consumer<ReviewViewModel>(
                        builder: (context, reviewVM, _) {
                          if (reviewVM.isLoading) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (reviewVM.reviews.isEmpty) {
                            return const Center(child: Text("No reviews yet."));
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: reviewVM.reviews.length,
                            itemBuilder: (context, index) {
                              final review = reviewVM.reviews[index];
                              return FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection("Users")
                                    .doc(review.userId)
                                    .get(),
                                builder: (context, userSnapshot) {
                                  if (userSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const SizedBox();
                                  }
                                  final userData = userSnapshot.data?.data()
                                      as Map<String, dynamic>?;
                                  final userName =
                                      userData?['name'] ?? "Unknown User";
                                  final userPic = userData?['profile_picture'];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundImage: userPic != null
                                                ? NetworkImage(userPic)
                                                : null,
                                            child: userPic == null
                                                ? const Icon(Icons.person)
                                                : null,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      userName,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                    Row(
                                                      children: List.generate(
                                                        5,
                                                        (i) => Icon(
                                                          i < review.stars
                                                              ? Icons.star
                                                              : Icons
                                                                  .star_border,
                                                          color: const Color
                                                              .fromARGB(
                                                              255, 170, 98, 153),
                                                          size: 18,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  review.comment,
                                                  style: const TextStyle(
                                                      fontSize: 14),
                                                ),
                                                if (review.imageUrl != null &&
                                                    review.imageUrl!.isNotEmpty)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 8.0),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      child: Image.network(
                                                        review.imageUrl!,
                                                        height: 140,
                                                        width: double.infinity,
                                                        fit: BoxFit.cover,
                                                      ),
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
                          );
                        },
                      ),
                    ],
                  ),
                  // Botón para escribir review
                  bottomNavigationBar: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 121, 39, 101),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  WriteReviewPage(restaurantId: fullRestaurant.id),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text("Write a Review"),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
