// lib/utils/review_isolate_helpers.dart

import 'dart:convert';

/// Serialize a list of reviews to a JSON string for local storage.
/// This function is isolate-safe (pure function).
String serializeReviewsForLocal(List<Map<String, dynamic>> reviewsJson) {
  return jsonEncode(reviewsJson);
}

/// Deserialize a JSON string into a list of maps.
/// Also isolate-safe.
List<Map<String, dynamic>> deserializeReviewsFromLocal(String jsonString) {
  final decoded = jsonDecode(jsonString);
  return List<Map<String, dynamic>>.from(decoded);
}

/// Save a pending review update payload (optimistic UI).
/// This runs inside compute() before writing to local DB or shared prefs.
Map<String, dynamic> savePendingUpdateIsolatePayload(
    Map<String, dynamic> payload) {
  // Identity function — you can transform if needed.
  return payload;
}
