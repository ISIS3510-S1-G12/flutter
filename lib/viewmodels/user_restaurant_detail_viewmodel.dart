// viewmodels/user_restaurant_detail_view_model.dart
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '/models/restaurant.dart';

class UserRestaurantDetailViewModel extends ChangeNotifier {
  bool isFavorite = false;

  Uint8List decodeBase64Image(String base64String) {
    final base64Data = base64String.split(',').last;
    return base64Decode(base64Data);
  }

  String formatTime(int time) {
    if (time < 0 || time > 2359) return "--:--";
    final hour = (time ~/ 100).toString().padLeft(2, '0');
    final minute = (time % 100).toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  Future<void> toggleFavorite(Restaurant restaurant) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final favRef = FirebaseFirestore.instance
        .collection('Favorites')
        .doc(user.uid)
        .collection('Restaurants')
        .doc(restaurant.id);

    final snapshot = await favRef.get();

    if (snapshot.exists) {
      await favRef.delete();
      isFavorite = false;
    } else {
      await favRef.set({
        'restaurant_id': FirebaseFirestore.instance
            .collection('Restaurants')
            .doc(restaurant.id),
        'name': restaurant.name,
        'imageUrl': restaurant.imageUrl,
        'offer': restaurant.offer,
        'typeOfFood': restaurant.typeOfFood,
        'addedAt': FieldValue.serverTimestamp(),
      });
      isFavorite = true;
    }

    notifyListeners();
  }

  Future<void> checkIfFavorite(Restaurant restaurant) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final favRef = FirebaseFirestore.instance
        .collection('Favorites')
        .doc(user.uid)
        .collection('Restaurants')
        .doc(restaurant.id);

    final snapshot = await favRef.get();
    isFavorite = snapshot.exists;
    notifyListeners();
  }

  /// Escaneo Bluetooth
  Future<int> scanNearbyDevices() async {
    List<String> detectedDevices = [];

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      for (var r in results) {
        if (!detectedDevices.contains(r.device.id.id)) {
          detectedDevices.add(r.device.id.id);
        }
      }
    });

    await Future.delayed(const Duration(seconds: 6));
    await FlutterBluePlus.stopScan();

    return detectedDevices.length;
  }
}
