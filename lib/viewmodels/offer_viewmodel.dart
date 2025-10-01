import 'package:flutter/foundation.dart';
import '../models/offer.dart';
import '../repositories/offer_repository.dart';

class OfferViewModel extends ChangeNotifier {
  final OfferRepository _offerRepo;

  OfferViewModel(this._offerRepo);

  Stream<List<Offer>> getOffers(String restaurantId) {
    return _offerRepo.getOffersByRestaurant(restaurantId);
  }

  Future<void> addOffer(Offer offer) async {
    await _offerRepo.createOffer(offer);
    notifyListeners();
  }
}
