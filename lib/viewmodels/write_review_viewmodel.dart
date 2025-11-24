import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class WriteReviewViewModel extends ChangeNotifier {
  final String restaurantId;
  WriteReviewViewModel(this.restaurantId);

  final formKey = GlobalKey<FormState>();
  final reviewController = TextEditingController();
  double rating = 3.0;
  bool loading = false;
  File? imageFile;
  final ImagePicker _picker = ImagePicker();

  /// 📸 Tomar foto
  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      imageFile = File(pickedFile.path);
      notifyListeners();
    }
  }

  /// 📝 Enviar reseña
  Future<void> submitReview(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;

    loading = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Usuario no autenticado");

      String? imageUrl;

      if (imageFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child("reviews/${DateTime.now().millisecondsSinceEpoch}.jpg");
        await ref.putFile(imageFile!);
        imageUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection("Reviews").add({
        "restaurant_id": restaurantId, //  solo el id
        "user_id": user.uid,           //  solo el id
        "stars": rating.toInt(),
        "comment": reviewController.text.trim(),
        "imageUrl": imageUrl,
        "createdAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reseña enviada")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al enviar reseña: $e")),
      );
    }

    loading = false;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getTopRestaurantsBySatisfaction() async {
  final rawReviews = await FirebaseFirestore.instance
      .collection("Reviews")
      .get();

  final Map<String, List<int>> groupedRatings = {};

  // Agrupar ratings por restaurant_id
  for (var doc in rawReviews.docs) {
    final restaurantId = doc["restaurant_id"];
    final stars = doc["stars"] ?? 0;

    if (!groupedRatings.containsKey(restaurantId)) {
      groupedRatings[restaurantId] = [];
    }
    groupedRatings[restaurantId]!.add(stars);
  }

  // Construir lista con promedios
  final List<Map<String, dynamic>> result = groupedRatings.entries.map((entry) {
    final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;

    return {
      "restaurant_id": entry.key,
      "average_rating": double.parse(avg.toStringAsFixed(2)),
      "reviews": entry.value.length,
    };
  }).toList();

  // Ordenar de mayor a menor
  result.sort((a, b) =>
      b["average_rating"].compareTo(a["average_rating"]));

  return result;
}










}
