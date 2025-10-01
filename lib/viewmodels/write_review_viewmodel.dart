import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WriteReviewViewModel extends ChangeNotifier {
  final String restaurantId;
  WriteReviewViewModel(this.restaurantId);

  final formKey = GlobalKey<FormState>();
  final reviewController = TextEditingController();
  double rating = 3.0;
  bool loading = false;
  File? imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      imageFile = File(pickedFile.path);
      notifyListeners();
    }
  }

  Future<void> submitReview(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;

    loading = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Usuario no autenticado");

      await FirebaseFirestore.instance.collection("Reviews").add({
        "restaurant_id": FirebaseFirestore.instance
            .collection("Restaurants")
            .doc(restaurantId),
        "user_id": FirebaseFirestore.instance
            .collection("Users")
            .doc(user.uid),
        "stars": rating.toInt(),
        "comment": reviewController.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Reseña enviada")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error al enviar reseña: $e")),
      );
    }

    loading = false;
    notifyListeners();
  }
}
