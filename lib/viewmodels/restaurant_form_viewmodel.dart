// lib/viewmodels/restaurant_form_viewmodel.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantFormViewModel extends ChangeNotifier {
  final String restaurantId;
  final formKey = GlobalKey<FormState>();

  bool isLoading = true;

  // Campos del restaurante
  String name = '';
  String address = '';
  String email = '';
  String typeOfFood = '';
  int? openingTime;
  int? closingTime;
  double? rating;
  bool hasOffer = false;
  String imageUrl = '';

  File? pickedImageFile;

  RestaurantFormViewModel(this.restaurantId);

  /// Cargar datos existentes desde Firestore
  Future<void> loadData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Restaurants')
          .doc(restaurantId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        name = data['name'] ?? '';
        address = data['address'] ?? '';
        email = data['email'] ?? '';
        typeOfFood = data['typeOfFood'] ?? '';
        openingTime = data['opening_time'];
        closingTime = data['closing_time'];
        rating = (data['rating'] != null)
            ? (data['rating'] as num).toDouble()
            : null;
        hasOffer = data['offer'] ?? false;
        imageUrl = data['imageUrl'] ?? '';
      }
    } catch (e) {
      debugPrint("Error loading restaurant data: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  /// Seleccionar imagen desde galería
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      pickedImageFile = File(picked.path);
      notifyListeners();
    }
  }

  /// Subir imagen a Firebase Storage y devolver la URL
  Future<String?> _uploadImage() async {
    if (pickedImageFile == null) return imageUrl.isNotEmpty ? imageUrl : null;

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('restaurants/$restaurantId/${DateTime.now().millisecondsSinceEpoch}.jpg');

      await ref.putFile(pickedImageFile!);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint("Error uploading image: $e");
      return null;
    }
  }

  /// Guardar datos en Firestore
  Future<void> saveRestaurantInfo(BuildContext context) async {
    try {
      final url = await _uploadImage();

      final docRef =
          FirebaseFirestore.instance.collection('Restaurants').doc(restaurantId);

      final doc = await docRef.get();

      final now = Timestamp.now();

      await docRef.set({
        'name': name,
        'address': address,
        'email': email,
        'typeOfFood': typeOfFood,
        'opening_time': openingTime,
        'closing_time': closingTime,
        'rating': rating ?? 0.0,
        'offer': hasOffer,
        'imageUrl': url ?? '',
        'updated_at': now,
        if (!doc.exists) 'created_at': now,
        if (!doc.exists) 'busiest_hours': [],
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error saving restaurant: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving: $e")),
        );
      }
    }
  }

  /// Alternar oferta
  void toggleOffer(bool value) {
    hasOffer = value;
    notifyListeners();
  }
}
