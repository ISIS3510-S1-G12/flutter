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

  ///  Crear oferta
  Future<void> createOffer(Offer offer, {File? image}) async {
    final docRef = _firestore.collection("Offers").doc();

    String? imageUrl;
    if (image != null) {
      imageUrl = await _uploadImage(image, docRef.id);
    }

    final newOffer = Offer(
      id: docRef.id,
      restaurantId: offer.restaurantId,
      title: offer.title,
      description: offer.description,
      discountPercentage: offer.discountPercentage,
      image: imageUrl ?? offer.image,
      tags: offer.tags,
      validFrom: offer.validFrom,
      validTo: offer.validTo,
      createdAt: DateTime.now(),
    );

    await docRef.set(newOffer.toMap());
  }

  ///  Actualizar oferta
  Future<void> updateOffer(Offer offer, {File? image}) async {
    final docRef = _firestore.collection("Offers").doc(offer.id);

    String? imageUrl = offer.image;
    if (image != null) {
      imageUrl = await _uploadImage(image, offer.id);
    }

    final updatedOffer = offer.copyWith(image: imageUrl);

    await docRef.update(updatedOffer.toMap());
  }

  ///  Eliminar oferta
  Future<void> deleteOffer(String offerId) async {
    await _firestore.collection("Offers").doc(offerId).delete();
  }

  ///  Obtener ofertas de un restaurante
  Stream<List<Offer>> getOffersByRestaurant(String restaurantId) {
    return _firestore
        .collection("Offers")
        .where("restaurantId", isEqualTo: restaurantId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Offer.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  ///  Obtener todas las ofertas
  Stream<List<Offer>> getAllOffers() {
    return _firestore
        .collection("Offers")
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Offer.fromMap(doc.data(), doc.id)).toList());
  }

  ///  Obtener ofertas activas de hoy
  Future<List<Offer>> getActiveOffers() async {
    final now = DateTime.now();

    final snapshot = await _firestore.collection("Offers").get();

    final offers = snapshot.docs.map((doc) {
      return Offer.fromMap(doc.data(), doc.id);
    }).toList();

    return offers.where((offer) {
      final from = offer.validFrom ?? DateTime(2000);
      final to = offer.validTo ?? DateTime(2100);
      return now.isAfter(from) && now.isBefore(to);
    }).toList();
  }
}
