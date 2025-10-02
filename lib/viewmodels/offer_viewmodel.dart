import 'package:flutter/foundation.dart';
import '../models/offer.dart';
import '../repositories/offer_repository.dart';

class OfferViewModel extends ChangeNotifier {
  final OfferRepository _offerRepo;

  OfferViewModel(this._offerRepo);

  String _selectedFilter = "All"; // "All" | "Today"
  String get selectedFilter => _selectedFilter;

  void changeFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  Stream<List<Offer>> getOffers(String restaurantId) {
    final baseStream = _offerRepo.getOffersByRestaurant(restaurantId);

    return baseStream.map((offers) {
      if (_selectedFilter == "All") return offers;

      final now = DateTime.now();
      return offers.where((offer) {
        if (offer.validFrom == null || offer.validTo == null) return false;
        return now.isAfter(offer.validFrom!) && now.isBefore(offer.validTo!);
      }).toList();
    });
  }

  Future<void> addOffer(Offer offer) async {
    await _offerRepo.createOffer(offer);
    notifyListeners();
  }
}
