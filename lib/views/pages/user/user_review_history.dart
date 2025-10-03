import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '/viewmodels/review_viewmodel.dart';
import '/repositories/review_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserReviewHistoryPage extends StatelessWidget {
  const UserReviewHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReviewViewModel(ReviewRepository()),
      child: Consumer<ReviewViewModel>(
        builder: (context, vm, _) {
          final user = FirebaseAuth.instance.currentUser;

          if (user != null && vm.reviews.isEmpty && !vm.isLoading) {
            vm.loadReviewsByUser(user.uid);
          }

          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    // 🔍 aquí podrías filtrar las reviews por texto si quieres
                  },
                ),
              ),
              Expanded(
                child: vm.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : vm.reviews.isEmpty
                        ? const Center(child: Text("No reviews yet."))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: vm.reviews.length,
                            itemBuilder: (context, index) {
                              final review = vm.reviews[index];
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

                                  final userData =
                                      userSnapshot.data?.data() as Map<
                                          String, dynamic>?;

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
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // 🔹 Avatar del usuario
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

                                          // 🔹 Contenido de la review
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
                                                    // ⭐ estrellas
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
                                                              255,
                                                              170,
                                                              98,
                                                              153),
                                                          size: 18,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),

                                                // 🔹 Nombre del restaurante
                                                FutureBuilder<
                                                    DocumentSnapshot>(
                                                  future: FirebaseFirestore
                                                      .instance
                                                      .collection("Restaurants")
                                                      .doc(review.restaurantId)
                                                      .get(),
                                                  builder: (context, snapshot) {
                                                    if (snapshot
                                                            .connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                      return const Text(
                                                        "Loading...",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500),
                                                      );
                                                    }
                                                    if (!snapshot.hasData ||
                                                        !snapshot.data!
                                                            .exists) {
                                                      return Text(
                                                        review.restaurantId,
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500),
                                                      );
                                                    }
                                                    final data = snapshot.data!
                                                            .data()
                                                        as Map<String, dynamic>;
                                                    final restaurantName =
                                                        data['name'] ??
                                                            review
                                                                .restaurantId;
                                                    return Text(
                                                      restaurantName,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 14,
                                                        color: Color.fromARGB(
                                                            255, 170, 98, 153),
                                                      ),
                                                    );
                                                  },
                                                ),
                                                const SizedBox(height: 6),

                                                // 🔹 Comentario
                                                Text(
                                                  review.comment,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black,
                                                  ),
                                                ),

                                                // 🔹 Imagen de la reseña
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
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}
