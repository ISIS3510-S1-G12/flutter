import 'dart:isolate';

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

    // 🔹 Future con handler + async/await
    return await FirebaseFirestore.instance
        .collection("Visits")
        .where("visitedAt", isGreaterThanOrEqualTo: oneWeekAgo)
        .get()
        .then((snapshot) async {
      final Map<String, int> visitCounts = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final restaurantId = data["restaurantId"];
        if (restaurantId != null) {
          visitCounts[restaurantId] = (visitCounts[restaurantId] ?? 0) + 1;
        }
      }

      // 🔹 Aquí podrías hacer algún otro await si necesitas procesar más datos
      await Future.delayed(const Duration(milliseconds: 1)); // ejemplo de async

      return visitCounts;
    });
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

    // Preparar datos para el isolate
    final List<Map<String, String>> visitsData = snapshot.docs.map((doc) {
      final data = doc.data();
      String restaurantId;
      String userId;

      final restaurantField = data["restaurantId"];
      final userField = data["userId"];

      restaurantId = restaurantField is DocumentReference
          ? restaurantField.id
          : restaurantField.toString();
      userId = userField is DocumentReference
          ? userField.id
          : userField.toString();

      return {"restaurantId": restaurantId, "userId": userId};
    }).toList();

    // Crear ReceivePort y Isolate
    final receivePort = ReceivePort();
    await Isolate.spawn(_loyaltyIsolate, [receivePort.sendPort, visitsData]);

    // Esperar resultado
    final result = await receivePort.first as Map<String, double>;
    print("✅ Loyalty rates calculated in isolate: $result");

    return result;
  } catch (e) {
    print("❌ Error al calcular tasas de lealtad: $e");
    return {};
  }
}

// Función del isolate
static void _loyaltyIsolate(List<dynamic> args) {
  final SendPort sendPort = args[0];
  final List<Map<String, String>> visitsData = args[1];

  final Map<String, int> visitCounts = {};
  final Map<String, Set<String>> restaurantUserMap = {};

  for (final visit in visitsData) {
    final restaurantId = visit["restaurantId"]!;
    final userId = visit["userId"]!;
    visitCounts[restaurantId] = (visitCounts[restaurantId] ?? 0) + 1;
    restaurantUserMap.putIfAbsent(restaurantId, () => <String>{});
    restaurantUserMap[restaurantId]!.add(userId);
  }

  final Map<String, double> loyaltyRates = {};
  visitCounts.forEach((restaurantId, totalVisits) {
    final uniqueUsers = restaurantUserMap[restaurantId]?.length ?? 1;
    final repeatVisits = (totalVisits - uniqueUsers).clamp(0, totalVisits);
    loyaltyRates[restaurantId] = totalVisits == 0 ? 0.0 : repeatVisits / totalVisits;
  });

  sendPort.send(loyaltyRates);
}

Future<List<Map<String, dynamic>>> getUserVisitedRestaurants() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final visits = await FirebaseFirestore.instance
        .collection("Visits")
        .where("userId", isEqualTo: user.uid)
        .orderBy("visitedAt", descending: true)
        .get();

    return visits.docs.map((doc) {
      final data = doc.data();
      return {
        "restaurantId": data["restaurantId"],
        "visitedAt": (data["visitedAt"] as Timestamp?)?.toDate(),
      };
    }).toList();
  } catch (e) {
    print("❌ Error loading user visits: $e");
    return [];
  }
}






}