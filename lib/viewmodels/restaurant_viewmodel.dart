import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/restaurant.dart';
import '../../models/user.dart' as app_user;
import '../../repositories/restaurant_repository.dart';
import '../../repositories/user_repository.dart';

/// --- FILTROS ---
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

/// --- VIEWMODEL ---
class RestaurantViewModel extends ChangeNotifier {
  final RestaurantRepository _restaurantRepo;
  final UserRepository _userRepo;

  RestaurantViewModel(this._restaurantRepo, this._userRepo);

  List<Restaurant> restaurants = [];
  List<Restaurant> filteredRestaurants = [];
  List<Restaurant> favorites = [];
  List<Restaurant> todaysDiscounts = [];

  bool isLoading = false;
  bool isLoadingFavorites = false;
  String? errorMessage;

  RestaurantFilter? _activeFilter;

  ///  NUEVOS GETTERS
  int get totalFavorites => favorites.length;

  int get favoritesWithOffers => todaysDiscounts.length;

  String get percentageWithOffers {
    if (favorites.isEmpty) return "0";
    final value = (todaysDiscounts.length / favorites.length) * 100;
    return value.toStringAsFixed(1); // ejemplo: 33.3
  }

  ///  Cargar todos los restaurantes
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

  ///  Guardar un restaurante con imagen
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

  ///  Cargar favoritos
  Future<void> fetchFavorites() async {
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

      final app_user.User? userData = await _userRepo.getUser(userAuth.uid);
      if (userData == null || userData.favoriteRestaurants.isEmpty) {
        favorites = [];
        todaysDiscounts = [];
      } else {
        favorites = await _restaurantRepo
            .getFavoriteRestaurants(userData.favoriteRestaurants);
        todaysDiscounts = favorites.where((r) => r.offer).toList();
      }

      isLoadingFavorites = false;
      notifyListeners();
    } catch (e) {
      isLoadingFavorites = false;
      errorMessage = e.toString();
      favorites = [];
      todaysDiscounts = [];
      notifyListeners();
    }
  }

  Future<void> fetchTodaysDiscounts() async {
    await fetchFavorites();
    todaysDiscounts = favorites.where((r) => r.offer).toList();
    notifyListeners();
  }

  /// --- FILTROS ---
  void applyFilter(RestaurantFilter filter) {
    _activeFilter = filter;
    filteredRestaurants = filter.apply(restaurants);
    notifyListeners();
  }

  void clearFilter() {
    _activeFilter = null;
    filteredRestaurants = restaurants;
    notifyListeners();
  }
}

