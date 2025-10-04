import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/visits_repository.dart';

class VisitViewModel extends ChangeNotifier {
  final VisitsRepository _visitsRepository;

  VisitViewModel(this._visitsRepository);

  bool isLoading = false;
  String? errorMessage;
  int? daysSinceLastVisit;

  /// Registrar visita
  Future<void> registerVisit(String restaurantId) async {
    try {
      isLoading = true;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      await _visitsRepository.registerVisit(restaurantId, user.uid);

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Calcular los días desde la última visita de este usuario a este restaurant
  Future<void> loadDaysSinceLastVisit(String restaurantId) async {
    try {
      isLoading = true;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final lastVisit =
          await _visitsRepository.getLastVisit(restaurantId, user.uid);

      if (lastVisit == null) {
        daysSinceLastVisit = null; // nunca visitado
      } else {
        final now = DateTime.now();
        daysSinceLastVisit = now.difference(lastVisit).inDays;
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }
}
