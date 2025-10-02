import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/offer.dart';

class OfferRepository {
  final _firestore = FirebaseFirestore.instance;

  /// 🔹 Subida de imagen
  Future<String> _uploadImage(File image, String offerId) async {
    final ref = FirebaseStorage.instance.ref().child("offers/$offerId.jpg");
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  /// 🔹 Crear una nueva oferta
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

  /// 🔹 Actualizar una oferta existente
  Future<void> updateOffer(Offer offer, {File? image}) async {
    final docRef = _firestore.collection("Offers").doc(offer.id);

    String? imageUrl = offer.image;
    if (image != null) {
      imageUrl = await _uploadImage(image, offer.id);
    }

    final updatedOffer = offer.copyWith(image: imageUrl);

    await docRef.update(updatedOffer.toMap());
  }

  /// 🔹 Ofertas por restaurante
  Stream<List<Offer>> getOffersByRestaurant(String restaurantId) {
    return _firestore
        .collection("Offers")
        .where("restaurantId", isEqualTo: restaurantId)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Offer.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  /// 🔹 Obtener todas las ofertas
  Stream<List<Offer>> getAllOffers() {
    return _firestore
        .collection("Offers")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Offer.fromMap(doc.data(), doc.id)).toList());
  }
}
