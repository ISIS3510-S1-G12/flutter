import 'package:cloud_firestore/cloud_firestore.dart';
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


    /// 🔹 Obtiene la cantidad de visitas de cada restaurante en la última semana.
  Future<Map<String, int>> getWeeklyVisitCounts() async {
    try {
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));

      final snapshot = await FirebaseFirestore.instance
          .collection("Visits")
          .where("visitedAt", isGreaterThanOrEqualTo: oneWeekAgo)
          .get();

      final Map<String, int> visitCounts = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final restaurantId = data["restaurantId"];
        if (restaurantId != null) {
          visitCounts[restaurantId] = (visitCounts[restaurantId] ?? 0) + 1;
        }
      }

      return visitCounts;
    } catch (e) {
      print("❌ Error al obtener visitas semanales: $e");
      return {};
    }
  }

  
    /// 🔹 Calcula la tasa de lealtad semanal basada en número total de visitas (no usuarios).
  Future<Map<String, double>> getWeeklyLoyaltyRates() async {
    try {
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));

      // Obtener todas las visitas de la última semana
      final snapshot = await FirebaseFirestore.instance
          .collection("Visits")
          .where("visitedAt", isGreaterThanOrEqualTo: oneWeekAgo)
          .get();

      final Map<String, List<String>> restaurantUserMap = {};
      final Map<String, int> visitCounts = {};

      // Contar total de visitas y usuarios únicos por restaurante
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final restaurantField = data["restaurantId"];
        final userField = data["userId"];

        // 🔧 Puede ser referencia o string
        String? restaurantId;
        String? userId;

        if (restaurantField is DocumentReference) {
          restaurantId = restaurantField.id;
        } else if (restaurantField is String) {
          restaurantId = restaurantField;
        }

        if (userField is DocumentReference) {
          userId = userField.id;
        } else if (userField is String) {
          userId = userField;
        }

        if (restaurantId == null || userId == null) continue;

        visitCounts[restaurantId] = (visitCounts[restaurantId] ?? 0) + 1;

        restaurantUserMap.putIfAbsent(restaurantId, () => []);
        if (!restaurantUserMap[restaurantId]!.contains(userId)) {
          restaurantUserMap[restaurantId]!.add(userId);
        }
      }

      // Calcular tasa de lealtad
      final Map<String, double> loyaltyRates = {};
      visitCounts.forEach((restaurantId, totalVisits) {
        final uniqueUsers = restaurantUserMap[restaurantId]?.length ?? 1;
        final repeatVisits = (totalVisits - uniqueUsers).clamp(0, totalVisits);
        final rate = totalVisits == 0 ? 0.0 : repeatVisits / totalVisits;
        loyaltyRates[restaurantId] = rate.toDouble();
      });

      print("✅ Loyalty rates calculated (by visits): $loyaltyRates");
      return loyaltyRates;
    } catch (e) {
      print("❌ Error al calcular tasas de lealtad: $e");
      return {}; 
    }
  }







}