import 'package:flutter/foundation.dart';
import '../models/offer.dart';
import '../repositories/offer_repository.dart';

class OfferViewModel extends ChangeNotifier {
  final OfferRepository _offerRepo;

  OfferViewModel(this._offerRepo);

  Offer? _selectedOffer;
  bool isLoading = false;

  Offer? get selectedOffer => _selectedOffer;

  Stream<List<Offer>> getOffers(String restaurantId) {
    return _offerRepo.getOffersByRestaurant(restaurantId);
  }

  Stream<List<Offer>> getAllOffers() {
    return _offerRepo.getAllOffers();
  }

  Stream<List<Offer>> getOffersByRestaurant(String restaurantId) {
    return _offerRepo.getOffersByRestaurant(restaurantId);
  }

  Future<void> addOffer(Offer offer) async {
    await _offerRepo.createOffer(offer);
    notifyListeners();
  }

  Future<void> updateOffer(Offer offer) async {
    await _offerRepo.updateOffer(offer);
    notifyListeners();
  }

  Future<void> loadOfferDetail(String offerId) async {
    isLoading = true;
    notifyListeners();

    // Busca primero en cache (gracias al repositorio)
    _selectedOffer = await _offerRepo.getOfferById(offerId);

    isLoading = false;
    notifyListeners();
  }

  //  Obtener detalle sin afectar el estado (opcional)
  Future<Offer?> getOfferDetail(String offerId) async {
    return await _offerRepo.getOfferById(offerId); // también usa cache
  }

  //  Obtener todas las ofertas solo una vez
  Future<List<Offer>> fetchAllOffersOnce() async {
    final stream = _offerRepo.getAllOffers();
    final offers = await stream.first; // se queda con la primera emisión
    return offers;
  }
}
