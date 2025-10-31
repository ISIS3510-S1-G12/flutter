import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/offer.dart';
import '../data/local_offer_db.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../cache/offer_cache.dart'; // 👈 Importar cache


class OfferRepository {
  final _firestore = FirebaseFirestore.instance;
  final _localDB = OfferDB();

  //  Cache en memoria
  final OfferCache _offerCache = OfferCache(); //  usa la clase global

  //  Verifica conexión
  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  //  Subir imagen a Firebase Storage
  Future<String> _uploadImage(File image, String offerId) async {
    final ref = FirebaseStorage.instance.ref().child("offers/$offerId.jpg");
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  //  Crear oferta (online u offline)
  Future<void> createOffer(Offer offer, {File? image}) async {
    final online = await _isOnline();

    if (online) {
      final docRef = _firestore.collection("Offers").doc();

      String? imageUrl;
      if (image != null) {
        imageUrl = await _uploadImage(image, docRef.id);
      }

      final newOffer = offer.copyWith(
        id: docRef.id,
        image: imageUrl ?? offer.image,
        createdAt: DateTime.now(),
        synced: true,
      );

      await docRef.set(newOffer.toMap());
      print(" Oferta subida a Firestore: ${newOffer.title}");
    } else {
      final localOffer = offer.copyWith(
        id: null,
        createdAt: DateTime.now(),
        synced: false,
      );
      await _localDB.insertOffer(localOffer);
      print(" Oferta guardada localmente (sin conexión): ${offer.title}");
    }
  }

  //  Sincronizar ofertas locales con Firestore
  Future<void> syncOffers() async {
    final unsynced = await _localDB.getUnsyncedOffers();

    for (var offer in unsynced) {
      final docRef = _firestore.collection("Offers").doc();
      await docRef.set(offer.toMap());
      await _localDB.markAsSynced(offer.localId!);
      print(" Oferta sincronizada: ${offer.title}");
    }
  }

  //  Actualizar oferta
  Future<void> updateOffer(Offer offer, {File? image}) async {
    final online = await _isOnline();

    if (!online) {
      print(" No hay conexión: no se puede actualizar Firestore");
      return;
    }

    if (offer.id == null) {
      throw Exception(' offer.id es null — no se puede actualizar una oferta sin ID.');
    }

    final docRef = _firestore.collection("Offers").doc(offer.id);

    String? imageUrl = offer.image;
    if (image != null) {
      imageUrl = await _uploadImage(image, offer.id!);
    }

    final updatedOffer = offer.copyWith(
      image: imageUrl,
      synced: true,
    );

    await docRef.update(updatedOffer.toMap());
    print(" Oferta actualizada correctamente: ${updatedOffer.title}");

    //  Actualizar también el cache
    _offerCache.put(updatedOffer.id!, updatedOffer);
  }

  //  Eliminar oferta
  Future<void> deleteOffer(String offerId) async {
    final online = await _isOnline();

    if (online) {
      await _firestore.collection("Offers").doc(offerId).delete();
      print(" Oferta eliminada de Firestore ($offerId)");
    } else {
      print(" No hay conexión: eliminación solo online");
    }

    //  Eliminar del cache
    if (_offerCache.contains(offerId)) {
      _offerCache.clear();
    }
  }

  //  Obtener ofertas por restaurante
  Stream<List<Offer>> getOffersByRestaurant(String restaurantId) {
    return _firestore
        .collection("Offers")
        .where("restaurant_id", isEqualTo: restaurantId)
        .snapshots()
        .map((snapshot) {
      final offers = snapshot.docs
          .map((doc) => Offer.fromMap(doc.data(), doc.id))
          .toList();

      //  Guardar todas las ofertas nuevas en cache
      for (var offer in offers) {
        _offerCache.put(offer.id!, offer);
      }

      return offers;
    });
  }

  //  Obtener todas las ofertas
  Stream<List<Offer>> getAllOffers() {
    return _firestore.collection("Offers").snapshots().map((snapshot) {
      final offers =
          snapshot.docs.map((doc) => Offer.fromMap(doc.data(), doc.id)).toList();

      for (var offer in offers) {
        _offerCache.put(offer.id!, offer);
      }

      return offers;
    });
  }

  //  Obtener solo ofertas activas
  Future<List<Offer>> getActiveOffers() async {
    final now = DateTime.now();
    final snapshot = await _firestore.collection("Offers").get();

    final offers =
        snapshot.docs.map((doc) => Offer.fromMap(doc.data(), doc.id)).toList();

    return offers.where((offer) {
      final from = offer.valid_from ?? DateTime(2000);
      final to = offer.valid_to ?? DateTime(2100);
      return now.isAfter(from) && now.isBefore(to);
    }).toList();
  }

  //  Obtener oferta por ID con cache
  Future<Offer?> getOfferById(String offerId) async {
    //  Buscar primero en el cache
    final cachedOffer = _offerCache.get(offerId);
    if (cachedOffer != null) {
      print(" Oferta obtenida desde cache: $offerId");
      return cachedOffer;
    }

    try {
      //  Si no está cacheada, buscar en Firestore
      final doc = await _firestore.collection('Offers').doc(offerId).get();
      if (doc.exists && doc.data() != null) {
        final offer = Offer.fromMap(doc.data()!, doc.id);
        _offerCache.put(offerId, offer); // guardar en cache
        print("Oferta obtenida desde Firestore y cacheada: $offerId");
        return offer;
      }
      return null;
    } catch (e) {
      print("Error getting offer: $e");
      return null;
    }
  }
}
