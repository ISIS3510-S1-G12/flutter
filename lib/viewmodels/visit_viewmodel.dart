import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/visits_repository.dart';

class VisitViewModel extends ChangeNotifier {
  final VisitsRepository _visitsRepository;

  VisitViewModel(this._visitsRepository);

  bool isLoading = false;

  /// Última visita general (en días) de todos los restaurantes
  int? daysSinceLastVisitGlobal;

  /// Registrar visita
  Future<void> registerVisit(String restaurantId) async {
    try {
      isLoading = true;
      notifyListeners();
      print("🔹 Registering visit for restaurant: $restaurantId");

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("❌ No user logged in");
        return;
      }

      await _visitsRepository.registerVisit(restaurantId, user.uid);

      print("✅ Visit registered successfully");

      // refrescar global
      await loadDaysSinceLastVisitGlobal();

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      print("❌ Error registering visit: $e");
      notifyListeners();
    }
  }

  /// Calcular los días desde la última visita global (cualquier restaurante)
  Future<void> loadDaysSinceLastVisitGlobal() async {
    try {
      isLoading = true;
      notifyListeners();
      print("🔹 Loading global days since last visit");

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("❌ No user logged in");
        return;
      }

      final visits = await _visitsRepository.getUserVisits(user.uid);

      if (visits.isEmpty) {
        daysSinceLastVisitGlobal = null;
        print("ℹ️ User has never visited any restaurant");
      } else {
        final lastVisit = visits.first; // ya vienen ordenados por fecha desc
        final now = DateTime.now();
        daysSinceLastVisitGlobal = now.difference(lastVisit).inDays;
        print("✅ Days since last visit (global): $daysSinceLastVisitGlobal");
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      print("❌ Error loading global last visit: $e");
      notifyListeners();
    }
  }
}
