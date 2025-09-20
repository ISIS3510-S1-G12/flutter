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
    return DefaultTabController(
      length: 4,
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
            tabAlignment: TabAlignment.fill,
            isScrollable: false,
            labelColor: Colors.black,
            indicatorColor: Color.fromARGB(255, 214, 145, 104),
            labelPadding: EdgeInsets.symmetric(horizontal: 3.0),
            tabs: [
              Tab(text: "Home"),
              Tab(text: "Favorites"),
              Tab(text: "Offers"),
              Tab(text: "Review History"),
            ],
          ),
        ),
        body: Column(
          children: [
            // 🔹 Barra de búsqueda
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
                                    color: Color.fromARGB(255, 170, 98, 153),
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
                            style: const TextStyle(fontSize: 14, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
