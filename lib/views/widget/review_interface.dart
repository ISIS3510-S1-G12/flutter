class Review {
  final String user;         // Ej: "rpl_03"
  final String restaurant;   // Ej: "Centro de Japon"
  final String comment;      // Ej: "Best meal ever"
  final double rating;       // Ej: 4.5

  Review({
    required this.user,
    required this.restaurant,
    required this.comment,
    required this.rating,
  });
}
