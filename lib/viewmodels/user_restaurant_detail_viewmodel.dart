import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '/models/restaurant.dart';

class UserRestaurantDetailViewModel extends ChangeNotifier {
  bool isFavorite = false;

  String formatTime(int time) {
    if (time < 0 || time > 2359) return "--:--";
    final hour = (time ~/ 100).toString().padLeft(2, '0');
    final minute = (time % 100).toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  ///Alternar favorito usando Users.favorite_restaurants
  Future<void> toggleFavorite(Restaurant restaurant) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('Users').doc(user.uid);

    final snapshot = await userRef.get();
    if (!snapshot.exists) return;

    final data = snapshot.data() as Map<String, dynamic>;
    final currentFavorites =
        Map<String, dynamic>.from(data["favorite_restaurants"] ?? {});

    if (currentFavorites.containsKey(restaurant.id)) {
      //Quitar de favoritos
      await userRef.update({
        "favorite_restaurants.${restaurant.id}": FieldValue.delete(),
        "updated_at": FieldValue.serverTimestamp(),
      });
      isFavorite = false;
    } else {
      //Agregar a favoritos con timestamp
      await userRef.update({
        "favorite_restaurants.${restaurant.id}": FieldValue.serverTimestamp(),
        "updated_at": FieldValue.serverTimestamp(),
      });
      isFavorite = true;
    }

    notifyListeners();
  }

  /// ✅ Verificar si está en favoritos
  Future<void> checkIfFavorite(Restaurant restaurant) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('Users').doc(user.uid);
    final snapshot = await userRef.get();
    if (!snapshot.exists) {
      isFavorite = false;
      notifyListeners();
      return;
    }

    final data = snapshot.data() as Map<String, dynamic>;
    final currentFavorites =
        Map<String, dynamic>.from(data["favorite_restaurants"] ?? {});

    isFavorite = currentFavorites.containsKey(restaurant.id);
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
