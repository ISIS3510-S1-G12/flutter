import 'package:cloud_firestore/cloud_firestore.dart';

class VisitsRepository {
  final _firestore = FirebaseFirestore.instance;

  /// 🔹 Registrar una nueva visita
  Future<void> registerVisit(String restaurantId, String userId) async {
    try {
      await _firestore.collection("Visits").add({
        "restaurantId": restaurantId,
        "userId": userId,
        "date": FieldValue.serverTimestamp(), // ⏰ hora del servidor
      });
    } catch (e) {
      rethrow;
    }
  }

  /// 🔹 Obtener la última visita de un usuario a un restaurante
  Future<DateTime?> getLastVisit(String restaurantId, String userId) async {
    try {
      final query = await _firestore
          .collection("Visits")
          .where("restaurantId", isEqualTo: restaurantId)
          .where("userId", isEqualTo: userId)
          .orderBy("date", descending: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      final data = query.docs.first.data();
      final timestamp = data["date"] as Timestamp?;
      return timestamp?.toDate();
    } catch (e) {
      rethrow;
    }
  }

  /// 🔹 Obtener todas las visitas de un usuario
  Future<List<DateTime>> getUserVisits(String userId) async {
    try {
      final query = await _firestore
          .collection("Visits")
          .where("userId", isEqualTo: userId)
          .orderBy("date", descending: true)
          .get();

      return query.docs
          .map((doc) {
            final ts = doc["date"] as Timestamp?;
            return ts?.toDate();
          })
          .whereType<DateTime>() // elimina nulos
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// 🔹 Obtener todas las visitas a un restaurante
  Future<List<DateTime>> getRestaurantVisits(String restaurantId) async {
    try {
      final query = await _firestore
          .collection("Visits")
          .where("restaurantId", isEqualTo: restaurantId)
          .orderBy("date", descending: true)
          .get();

      return query.docs
          .map((doc) {
            final ts = doc["date"] as Timestamp?;
            return ts?.toDate();
          })
          .whereType<DateTime>()
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
