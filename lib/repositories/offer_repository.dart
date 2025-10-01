import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/offer.dart';

class OfferRepository {
  final _firestore = FirebaseFirestore.instance;

  Stream<List<Offer>> getOffersByRestaurant(String restaurantId) {
    final restaurantRef =
        _firestore.collection("Restaurants").doc(restaurantId);

    return _firestore
        .collection("Offers")
        .where("restaurant_id", isEqualTo: restaurantRef)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Offer.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> createOffer(Offer offer) async {
    await _firestore.collection("Offers").add(offer.toMap());
  }
}
