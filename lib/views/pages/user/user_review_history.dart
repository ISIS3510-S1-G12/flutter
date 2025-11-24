import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:moviles/repositories/review_cache.dart';
import 'package:moviles/views/pages/user/edit_review_page.dart';
import 'package:provider/provider.dart';
import '/viewmodels/review_viewmodel.dart';
import '/repositories/review_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/models/review.dart';

class UserReviewHistoryPage extends StatefulWidget {
  const UserReviewHistoryPage({super.key});

  @override
  State<UserReviewHistoryPage> createState() => _UserReviewHistoryPageState();
}

class _UserReviewHistoryPageState extends State<UserReviewHistoryPage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReviewViewModel(ReviewRepository()),
      child: Consumer<ReviewViewModel>(
        builder: (context, vm, _) {
          final user = FirebaseAuth.instance.currentUser;

          // Cargar reseñas del usuario solo si aún no están
          if (user != null && vm.reviews.isEmpty && !vm.isLoading) {
            vm.loadReviewsByUser(user.uid);
          }

          return Column(
            children: [
              // Banner: último restaurante reseñado
              if (vm.reviews.isNotEmpty)
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection("Restaurants")
                      .doc(vm.reviews.last.restaurantId)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: LinearProgressIndicator(),
                      );
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const SizedBox();
                    }

                    final data =
                        snapshot.data!.data() as Map<String, dynamic>? ?? {};
                    final name = data['name'] ?? 'Unknown Restaurant';

                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 240, 222, 214),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color.fromARGB(255, 214, 145, 104)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.rate_review,
                                color: Color.fromARGB(255, 214, 145, 104)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "📝 Your last review was for: $name",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              // Campo de búsqueda
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search a review",
                    hintStyle: const TextStyle(color: Colors.white),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    filled: true,
                    fillColor: const Color.fromARGB(255, 214, 145, 104),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (query) {
                    // Puedes implementar búsqueda aquí
                  },
                ),
              ),

              // Lista de reseñas
              Expanded(
                child: vm.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : vm.reviews.isEmpty
                        ? const Center(child: Text("No reviews yet."))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: vm.reviews.length,
                            itemBuilder: (context, index) {
                              final originalReview = vm.reviews[index];

                              // Tomar la versión más reciente de la review
                              final updatedReview = vm.reviews.firstWhere(
                                (r) => r.id == originalReview.id,
                                orElse: () => originalReview,
                              );

                              final review = updatedReview;

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
                                    margin: const EdgeInsets.only(bottom: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
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
                                                  Text(
                                                    userName,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: List.generate(
                                                  5,
                                                  (i) => Icon(
                                                    i < review.stars
                                                        ? Icons.star
                                                        : Icons.star_border,
                                                    color: const Color.fromARGB(
                                                        255, 170, 98, 153),
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          FutureBuilder<DocumentSnapshot>(
                                            future: FirebaseFirestore.instance
                                                .collection("Restaurants")
                                                .doc(review.restaurantId)
                                                .get(),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return const Text(
                                                  "Loading...",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500),
                                                );
                                              }
                                              if (!snapshot.hasData ||
                                                  !snapshot.data!.exists) {
                                                return Text(
                                                  review.restaurantId,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500),
                                                );
                                              }
                                              final data = snapshot.data!.data()
                                                  as Map<String, dynamic>;
                                              final restaurantName =
                                                  data['name'] ?? review.restaurantId;
                                              return Text(
                                                restaurantName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                  color: Color.fromARGB(
                                                      255, 170, 98, 153),
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            review.comment,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black,
                                            ),
                                          ),
                                          if (review.imageUrl != null &&
                                              review.imageUrl!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: CachedNetworkImage(
                                                  imageUrl: review.imageUrl!,
                                                  height: 140,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) =>
                                                      const Center(
                                                          child:
                                                              CircularProgressIndicator()),
                                                  errorWidget:
                                                      (context, url, error) =>
                                                          const Icon(Icons.error),
                                                ),
                                              ),
                                            ),
                                          // Botón de editar
                                          if (review.userId == user?.uid)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Align(
                                                alignment: Alignment.centerRight,
                                                child: ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color.fromARGB(
                                                        255, 121, 39, 101),
                                                    foregroundColor: Colors.white,
                                                  ),
                                                  icon: const Icon(Icons.edit),
                                                  label: const Text("Edit Review"),
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            EditReviewPage(
                                                          reviewId: review.id,
                                                          restaurantId:
                                                              review.restaurantId,
                                                          initialComment:
                                                              review.comment,
                                                          initialStars: review.stars,
                                                          initialImageUrl:
                                                              review.imageUrl,
                                                        ),
                                                      ),
                                                    ).then((_) async {
                                                      if (user != null) {
                                                        // 🔹 Eliminar review del cache
                                                        ReviewCache.removeFromUser(
                                                            user.uid, review.id);
                                                        ReviewCache.removeFromRestaurant(
                                                            review.restaurantId,
                                                            review.id);
                                                        if (review.dishId != null) {
                                                          ReviewCache.removeFromDish(
                                                              review.dishId!, review.id);
                                                        }

                                                        // 🔹 Recargar reseñas actualizadas
                                                        await vm.loadReviewsByUser(user.uid);
                                                      }
                                                    });
                                                  },
                                                ),
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
          );
        },
      ),
    );
  }
}