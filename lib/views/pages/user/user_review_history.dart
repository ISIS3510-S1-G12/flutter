import 'package:flutter/material.dart';
import '/views/widget/review_interface.dart';

final List<Review> reviews = [
  Review(
    user: "rpl_03",
    restaurant: "Centro de Japon",
    comment: "Best meal ever",
    rating: 5,
  ),
  Review(
    user: "rpl_03",
    restaurant: "Monserrat",
    comment: "Its fine",
    rating: 3,
  ),
  Review(
    user: "rpl_03",
    restaurant: "Cunks BBQ",
    comment: "I really like this",
    rating: 4,
  ),
  Review(
    user: "rpl_03",
    restaurant: "Mulita",
    comment: "I will not buy this again",
    rating: 1,
  ),
  Review(
    user: "rpl_03",
    restaurant: "Jack Daniels",
    comment: "I loved this hamburger so much",
    rating: 5,
  ),
];

class UserReviewHistoryPage extends StatelessWidget {
  const UserReviewHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "${review.user} - ",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                TextSpan(
                                  text: review.restaurant,
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 170, 98, 153),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < review.rating.round()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: const Color.fromARGB(255, 170, 98, 153),
                                size: 18,
                              ),
                            ),
                          ),
                        ],
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
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
