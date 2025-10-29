
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/visits_repository.dart';

class PopularityViewModel extends ChangeNotifier {
  final VisitsRepository _visitsRepository;

  PopularityViewModel(this._visitsRepository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Map<String, int> _visitCounts = {};
  Map<String, int> get visitCounts => _visitCounts;

  String? _mostVisitedRestaurantId;
  String? get mostVisitedRestaurantId => _mostVisitedRestaurantId;

  Future<void> calculateWeeklyPopularity() async {
    _isLoading = true;
    notifyListeners();

    try {
      final counts = await _visitsRepository.getWeeklyVisitCounts();
      _visitCounts = counts;

      if (counts.isNotEmpty) {
        _mostVisitedRestaurantId =
            counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      }
    } catch (e) {
      debugPrint("Error calculating popularity: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Permite que un restaurante consulte si fue el más visitado
  bool isRestaurantMostVisited(String restaurantId) {
    return restaurantId == _mostVisitedRestaurantId;
  }

  int getVisitsForRestaurant(String restaurantId) {
    return _visitCounts[restaurantId] ?? 0;
  }
} 

