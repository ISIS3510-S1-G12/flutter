import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/restaurant.dart';
import '../../models/user.dart' as app_user;
import '../../repositories/restaurant_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/offer_repository.dart';
import '../../repositories/hive_favorites_cache.dart'; // 🐝 Nuevo
import '../../cache/restaurant_cache.dart'; //  NUEVO

///  FILTROS (Strategy Pattern) 

abstract class RestaurantFilter {
  List<Restaurant> apply(List<Restaurant> restaurants);
}

class FilterByType implements RestaurantFilter {
  final String query;
  FilterByType(this.query);

  @override
  List<Restaurant> apply(List<Restaurant> restaurants) {
    return restaurants
        .where((r) => r.typeOfFood.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}

class FilterWithOffer implements RestaurantFilter {
  @override
  List<Restaurant> apply(List<Restaurant> restaurants) {
    return restaurants.where((r) => r.offer).toList();
  }
}

class FilterWithoutOffer implements RestaurantFilter {
  @override
  List<Restaurant> apply(List<Restaurant> restaurants) {
    return restaurants.where((r) => !r.offer).toList();
  }
}

class FilterContext {
  RestaurantFilter? _strategy;

  void setStrategy(RestaurantFilter strategy) {
    _strategy = strategy;
  }

  void clearStrategy() {
    _strategy = null;
  }

  List<Restaurant> execute(List<Restaurant> restaurants) {
    if (_strategy == null) return restaurants;
    return _strategy!.apply(restaurants);
  }
}

///  VIEWMODEL 
class RestaurantViewModel extends ChangeNotifier {
  final RestaurantRepository _restaurantRepo;
  final UserRepository _userRepo;
  final OfferRepository _offerRepo;
  final HiveFavoritesCache _favoritesCache = HiveFavoritesCache(); // 🐝

  RestaurantViewModel(this._restaurantRepo, this._userRepo, this._offerRepo);

  final FilterContext _filterContext = FilterContext();

  // Listas principales
  List<Restaurant> restaurants = [];
  List<Restaurant> filteredRestaurants = [];
  List<Restaurant> favorites = [];
  List<Restaurant> todaysDiscounts = [];

  // Variables de estado
  bool isLoading = false;
  bool isLoadingFavorites = false;
  String? errorMessage;

  StreamSubscription<List<Restaurant>>? _favoritesSubscription;

  //   Manejo del detalle de restaurante con cache LRU
  Restaurant? _selectedRestaurant;
  bool isLoadingDetail = false;

  Restaurant? get selectedRestaurant => _selectedRestaurant;

  Future<void> loadRestaurantDetail(String restaurantId) async {
    isLoadingDetail = true;
    notifyListeners();

    //  Buscar primero en cache
    final cached = RestaurantCache.get(restaurantId);
    if (cached != null) {
      print(" [LRU] Detalle obtenido desde cache: ${cached.name}");
      _selectedRestaurant = cached;
      isLoadingDetail = false;
      notifyListeners();
      return;
    }

    //  Si no está, buscar en Firestore y guardar en cache
    final restaurant = await _restaurantRepo.getRestaurantById(restaurantId);
    if (restaurant != null) {
      RestaurantCache.put(restaurantId, restaurant);
      print(" [Firestore] Detalle cacheado: ${restaurant.name}");
      _selectedRestaurant = restaurant;
    }

    isLoadingDetail = false;
    notifyListeners();
  }

  void clearSelectedRestaurant() {
    _selectedRestaurant = null;
    notifyListeners();
  }

  ///  CARGAR RESTAURANTES 
  Future<void> fetchRestaurants() async {
    try {
      isLoading = true;
      notifyListeners();

      restaurants = await _restaurantRepo.getRestaurants();
      filteredRestaurants = restaurants;

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  ///  GUARDAR RESTAURANTE 
  Future<void> saveRestaurantOwner({
    required String id,
    required String name,
    required String email,
    required String address,
    required String typeOfFood,
    required bool offer,
    File? imageFile,
  }) async {
    try {
      isLoading = true;
      notifyListeners();

      String imageUrl = "";
      if (imageFile != null) {
        imageUrl = await _restaurantRepo.uploadImage(id, imageFile);
      }

      final restaurant = Restaurant(
        id: id,
        name: name,
        email: email,
        address: address,
        typeOfFood: typeOfFood,
        offer: offer,
        imageUrl: imageUrl,
        openingTime: 9,
        closingTime: 22,
        busiestHours: {},
        rating: 0.0,
      );

      await _restaurantRepo.saveRestaurantWithId(id, restaurant);
      await fetchRestaurants();

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  ///  CARGAR FAVORITOS 
  Future<void> fetchFavorites({bool fromCache = false}) async {
    try {
      isLoadingFavorites = true;
      notifyListeners();

      final userAuth = FirebaseAuth.instance.currentUser;
      if (userAuth == null) {
        favorites = [];
        todaysDiscounts = [];
        isLoadingFavorites = false;
        notifyListeners();
        return;
      }

      // Si se solicita cargar desde caché (sin conexión)
      if (fromCache) {
        favorites = await _favoritesCache.getCachedFavorites();
        isLoadingFavorites = false;
        notifyListeners();
        return;
      }

      final app_user.User? userData = await _userRepo.getUser(userAuth.uid);
      if (userData == null || userData.favoriteRestaurants.isEmpty) {
        favorites = [];
        todaysDiscounts = [];
      } else {
        favorites = await _restaurantRepo
            .getFavoriteRestaurants(userData.favoriteRestaurants);

        //  Guardar en caché local
        await _favoritesCache.cacheFavorites(favorites);

        final activeOffers = await _offerRepo.getActiveOffers();
        todaysDiscounts = favorites.where((restaurant) {
          return activeOffers.any((offer) => offer.restaurant_id == restaurant.id);
        }).toList();
      }

      isLoadingFavorites = false;
      notifyListeners();
    } catch (e) {
      isLoadingFavorites = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  ///  ESCUCHAR FAVORITOS EN TIEMPO REAL 
  Future<void> listenToFavoritesStream() async {
    final userAuth = FirebaseAuth.instance.currentUser;
    if (userAuth == null) return;

    final app_user.User? userData = await _userRepo.getUser(userAuth.uid);
    if (userData == null || userData.favoriteRestaurants.isEmpty) return;

    await _favoritesSubscription?.cancel();

    _favoritesSubscription = _restaurantRepo
        .getFavoriteRestaurantsStream(userData.favoriteRestaurants)
        .listen((favList) async {
      favorites = favList;

      //  Actualiza la caché cada vez que llega un nuevo stream
      await _favoritesCache.cacheFavorites(favorites);

      final activeOffers = await _offerRepo.getActiveOffers();
      todaysDiscounts = favorites.where((r) {
        return activeOffers.any((o) => o.restaurant_id == r.id);
      }).toList();

      notifyListeners();
    });
  }

  ///  CANCELAR EL STREAM 
  void cancelFavoritesListener() {
    _favoritesSubscription?.cancel();
    _favoritesSubscription = null;
  }

  ///  DESCUENTOS 
  Future<void> fetchTodaysDiscounts() async {
    await fetchFavorites();
    todaysDiscounts = favorites.where((r) => r.offer).toList();
    notifyListeners();
  }

  ///  FILTROS 
  void applyFilter(RestaurantFilter filter) {
    _filterContext.setStrategy(filter);
    filteredRestaurants = _filterContext.execute(restaurants);
    notifyListeners();
  }

  void clearFilter() {
    _filterContext.clearStrategy();
    filteredRestaurants = restaurants;
    notifyListeners();
  }
}
