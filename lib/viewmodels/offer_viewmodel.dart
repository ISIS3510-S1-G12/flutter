import 'package:flutter/foundation.dart';
import '../models/offer.dart';
import '../repositories/offer_repository.dart';

class OfferViewModel extends ChangeNotifier {
  final OfferRepository _offerRepo;

  OfferViewModel(this._offerRepo);

  /// 🔹 Ofertas por restaurante
  Stream<List<Offer>> getOffers(String restaurantId) {
    return _offerRepo.getOffersByRestaurant(restaurantId);
  }

  /// 🔹 Todas las ofertas (para usuarios)
  Stream<List<Offer>> getAllOffers() {
    return _offerRepo.getAllOffers();
  }

  /// 🔹 Crear una oferta
  Future<void> addOffer(Offer offer) async {
    await _offerRepo.createOffer(offer);
    notifyListeners();
  }

  /// 🔹 Actualizar una oferta
  Future<void> updateOffer(Offer offer) async {
    await _offerRepo.updateOffer(offer);
    notifyListeners();
  }

  Stream<List<Offer>> getOffersByRestaurant(String restaurantId) {
  return _offerRepo.getOffersByRestaurant(restaurantId);
}
}
