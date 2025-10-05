import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/offer.dart';

class OfferRepository {
  final _firestore = FirebaseFirestore.instance;

  Future<String> _uploadImage(File image, String offerId) async {
    final ref = FirebaseStorage.instance.ref().child("offers/$offerId.jpg");
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  Future<void> createOffer(Offer offer, {File? image}) async {
    final docRef = _firestore.collection("Offers").doc();

    String? imageUrl;
    if (image != null) {
      imageUrl = await _uploadImage(image, docRef.id);
    }

    final newOffer = Offer(
      id: docRef.id,
      restaurant_id: offer.restaurant_id,
      title: offer.title,
      description: offer.description,
      discount_percentage: offer.discount_percentage,
      price: offer.price, // 👈 incluimos price
      image: imageUrl ?? offer.image,
      tags: offer.tags,
      valid_from: offer.valid_from,
      valid_to: offer.valid_to,
      createdAt: DateTime.now(),
    );

    await docRef.set(newOffer.toMap());
  }

  Future<void> updateOffer(Offer offer, {File? image}) async {
    final docRef = _firestore.collection("Offers").doc(offer.id);

    String? imageUrl = offer.image;
    if (image != null) {
      imageUrl = await _uploadImage(image, offer.id);
    }

    final updatedOffer = offer.copyWith(image: imageUrl);

    await docRef.update(updatedOffer.toMap());
  }

  Future<void> deleteOffer(String offerId) async {
    await _firestore.collection("Offers").doc(offerId).delete();
  }

  Stream<List<Offer>> getOffersByRestaurant(String restaurantId) {
    return _firestore
        .collection("Offers")
        .where("restaurant_id", isEqualTo: restaurantId) // 👈 snake_case
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Offer.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Stream<List<Offer>> getAllOffers() {
    return _firestore
        .collection("Offers")
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Offer.fromMap(doc.data(), doc.id)).toList());
  }

  Future<List<Offer>> getActiveOffers() async {
    final now = DateTime.now();

    final snapshot = await _firestore.collection("Offers").get();

    final offers = snapshot.docs.map((doc) {
      return Offer.fromMap(doc.data(), doc.id);
    }).toList();

    return offers.where((offer) {
      final from = offer.valid_from ?? DateTime(2000);
      final to = offer.valid_to ?? DateTime(2100);
      return now.isAfter(from) && now.isBefore(to);
    }).toList();
  }
}
