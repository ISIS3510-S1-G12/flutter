import 'package:flutter/foundation.dart';
import '../models/offer.dart';
import '../repositories/offer_repository.dart';

class OfferViewModel extends ChangeNotifier {
  final OfferRepository _offerRepo;

  OfferViewModel(this._offerRepo);

  Stream<List<Offer>> getOffers(String restaurantId) {
    return _offerRepo.getOffersByRestaurant(restaurantId);
  }

  Stream<List<Offer>> getAllOffers() {
    return _offerRepo.getAllOffers();
  }

  Future<void> addOffer(Offer offer) async {
    await _offerRepo.createOffer(offer);
    notifyListeners();
  }
  
  Future<void> updateOffer(Offer offer) async {
    await _offerRepo.updateOffer(offer);
    notifyListeners();
  }

  Stream<List<Offer>> getOffersByRestaurant(String restaurantId) {
  return _offerRepo.getOffersByRestaurant(restaurantId);
}
}
