import 'package:cloud_firestore/cloud_firestore.dart';

class VisitsRepository {
  final _firestore = FirebaseFirestore.instance;

  Future<void> registerVisit(String restaurantId, String userId) async {
    try {
      await _firestore.collection("Visits").add({
        "restaurantId": restaurantId,
        "userId": userId,
        "visitedAt": FieldValue.serverTimestamp(), 
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<DateTime?> getLastVisit(String restaurantId, String userId) async {
    try {
      final query = await _firestore
          .collection("Visits")
          .where("restaurantId", isEqualTo: restaurantId)
          .where("userId", isEqualTo: userId)
          .orderBy("visitedAt", descending: true) // 👈 corregido
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      final data = query.docs.first.data();
      final timestamp = data["visitedAt"] as Timestamp?;
      return timestamp?.toDate();
    } catch (e) {
      rethrow;
    }
  }


  Future<DateTime?> getLastVisitGlobal(String userId) async {
    try {
      final query = await _firestore
          .collection("Visits")
          .where("userId", isEqualTo: userId)
          .orderBy("visitedAt", descending: true) // 👈 corregido
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      final data = query.docs.first.data();
      final timestamp = data["visitedAt"] as Timestamp?;
      return timestamp?.toDate();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<DateTime>> getUserVisits(String userId) async {
    try {
      final query = await _firestore
          .collection("Visits")
          .where("userId", isEqualTo: userId)
          .orderBy("visitedAt", descending: true) // 👈 corregido
          .get();

      return query.docs
          .map((doc) {
            final ts = doc["visitedAt"] as Timestamp?;
            return ts?.toDate();
          })
          .whereType<DateTime>()
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<DateTime>> getRestaurantVisits(String restaurantId) async {
    try {
      final query = await _firestore
          .collection("Visits")
          .where("restaurantId", isEqualTo: restaurantId)
          .orderBy("visitedAt", descending: true) // 👈 corregido
          .get();

      return query.docs
          .map((doc) {
            final ts = doc["visitedAt"] as Timestamp?;
            return ts?.toDate();
          })
          .whereType<DateTime>()
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getVisitsInLastWeek() async {
  try {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final query = await _firestore
        .collection("Visits")
        .where("visitedAt", isGreaterThanOrEqualTo: weekAgo)
        .get();
    return query.docs;
  } catch (e) {
    rethrow;
  }
}

Future<Map<String, int>> getWeeklyVisitCounts() async {
  try {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final query = await _firestore
        .collection("Visits")
        .where("visitedAt", isGreaterThanOrEqualTo: weekAgo)
        .get();

    final Map<String, int> visitCounts = {};

    for (var doc in query.docs) {
      final data = doc.data();
      final restaurantRef = data['restaurantId'];
      if (restaurantRef == null) continue;

      final restaurantId = restaurantRef is DocumentReference
          ? restaurantRef.id
          : restaurantRef.toString();

      visitCounts[restaurantId] = (visitCounts[restaurantId] ?? 0) + 1;
    }

    return visitCounts;
  } catch (e) {
    rethrow;
  }
}


 



}