import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class RestaurantEditForm extends StatefulWidget {
  const RestaurantEditForm({super.key});

  @override
  State<RestaurantEditForm> createState() => _RestaurantEditFormState();
}

class _RestaurantEditFormState extends State<RestaurantEditForm> {
  bool loading = true;
  bool isOffline = false;
  String? restaurantId;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final typeController = TextEditingController();
  final openingController = TextEditingController();
  final closingController = TextEditingController();
  final busiestController = TextEditingController();
  final ratingController = TextEditingController();
  final offerController = TextEditingController();
  final ownerController = TextEditingController();

  File? newImage;
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    loadRestaurantData();
    monitorConnectivity();
  }

  void monitorConnectivity() {
    Connectivity().onConnectivityChanged.listen((result) async {
      if (result == ConnectivityResult.none) {
        print("DEBUG: Usuario quedó OFFLINE");
        isOffline = true;

        // ALERTA de que está offline
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Offline"),
            content: const Text(
              "You are currently offline. Changes to the restaurant will be saved locally.",
            ),
            actions: [
              TextButton(
                child: const Text("Ok"),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
        );

      } else {
        print("DEBUG: Usuario ONLINE");
        isOffline = false;
        await syncPendingChanges();
      }
      setState(() {});
    });
  }

  Future<void> loadRestaurantData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final query = await FirebaseFirestore.instance
        .collection("Restaurants")
        .where("ownerUid", isEqualTo: uid)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      setState(() => loading = false);
      return;
    }

    final doc = query.docs.first;
    restaurantId = doc.id;

    final data = doc.data();

    nameController.text = data["name"] ?? "";
    emailController.text = data["email"] ?? "";
    addressController.text = data["address"] ?? "";
    typeController.text = data["typeOfFood"] ?? "";
    openingController.text = data["opening_time"].toString();
    closingController.text = data["closing_time"].toString();
    ratingController.text = data["rating"].toString();
    busiestController.text = data["busiest_hours"]?["1200"] ?? "";
    offerController.text = data["offer"].toString();
    ownerController.text = data["ownerUid"] ?? "";

    imageUrl = data["imageUrl"];

    setState(() => loading = false);
  }

  Future selectImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        newImage = File(picked.path);
      });
    }
  }

  Future<String?> uploadImage() async {
    if (newImage == null) return imageUrl;

    try {
      final ref =
          FirebaseStorage.instance.ref().child("restaurants/$restaurantId.jpg");

      await ref.putFile(newImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      print("Image upload error: $e");
      return imageUrl;
    }
  }

  Future<void> saveChanges() async {
    if (restaurantId == null) return;

    final updateData = {
      "name": nameController.text,
      "email": emailController.text,
      "address": addressController.text,
      "typeOfFood": typeController.text,
      "opening_time": int.tryParse(openingController.text) ?? 0,
      "closing_time": int.tryParse(closingController.text) ?? 0,
      "rating": double.tryParse(ratingController.text) ?? 0.0,
      "offer": offerController.text.toLowerCase() == "true",
      "busiest_hours": busiestController.text,
      "imagePath": newImage?.path,
    };

    if (isOffline) {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString("pendingEdit", updateData.toString());
      await prefs.setBool("pendingSync", true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Restaurant changes saved offline. They will be synced later."),
        ),
      );

      return;
    }

    final uploadedUrl = await uploadImage();

    await FirebaseFirestore.instance
        .collection("Restaurants")
        .doc(restaurantId)
        .update({
      ...updateData,
      "busiest_hours": {"1200": busiestController.text},
      "imageUrl": uploadedUrl ?? imageUrl,
      "updated_at": DateTime.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Restaurant updated successfully.")),
    );

    Navigator.pop(context);
  }

  Future<void> syncPendingChanges() async {
    final prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey("pendingEdit")) return;

    final raw = prefs.getString("pendingEdit");
    if (raw == null) return;

    print("DEBUG: Sincronizando cambios pendientes: $raw");

    final map = _stringToMap(raw);

    String? finalImageUrl = imageUrl;
    if (map["imagePath"] != null) {
      final file = File(map["imagePath"]);
      if (file.existsSync()) {
        final ref = FirebaseStorage.instance
            .ref()
            .child("restaurants/$restaurantId.jpg");
        await ref.putFile(file);
        finalImageUrl = await ref.getDownloadURL();
      }
    }

    try {
      await FirebaseFirestore.instance
          .collection("Restaurants")
          .doc(restaurantId)
          .update({
        "name": map["name"],
        "email": map["email"],
        "address": map["address"],
        "typeOfFood": map["typeOfFood"],
        "opening_time": int.tryParse(map["opening_time"] ?? "0") ?? 0,
        "closing_time": int.tryParse(map["closing_time"] ?? "0") ?? 0,
        "rating": double.tryParse(map["rating"] ?? "0") ?? 0.0,
        "offer": map["offer"] == "true",
        "busiest_hours": {"1200": map["busiest_hours"] ?? ""},
        "imageUrl": finalImageUrl ?? imageUrl,
        "updated_at": DateTime.now(),
      });

      await prefs.remove("pendingEdit");
      await prefs.remove("pendingSync");

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Sincronización completada"),
          content:
              const Text("Los cambios pendientes del restaurante se sincronizaron correctamente."),
          actions: [
            TextButton(
              child: const Text("Ok"),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
      );

    } catch (e) {

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error"),
          content: Text("No se pudo sincronizar el restaurante: $e"),
          actions: [
            TextButton(
              child: const Text("Ok"),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
      );
    }
  }

  Map<String, dynamic> _stringToMap(String raw) {
    raw = raw.replaceAll("{", "").replaceAll("}", "");
    final pairs = raw.split(",");

    final map = <String, dynamic>{};

    for (var p in pairs) {
      final kv = p.split(":");
      if (kv.length == 2) {
        map[kv[0].trim()] = kv[1].trim();
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F4),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 214, 145, 104),
        title: const Text("Edit Restaurant"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: selectImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[300],
                backgroundImage: newImage != null
                    ? FileImage(newImage!)
                    : (imageUrl != null && imageUrl!.isNotEmpty)
                        ? NetworkImage(imageUrl!)
                        : null,
                child: (newImage == null &&
                        (imageUrl == null || imageUrl!.isEmpty))
                    ? const Icon(Icons.camera_alt, size: 40)
                    : null,
              ),
            ),

            const SizedBox(height: 8),
            const Text("Tap to change restaurant image"),

            const SizedBox(height: 30),

            buildInput("Name", nameController),
            buildInput("Email", emailController),
            buildInput("Address", addressController),
            buildInput("Type of Food", typeController),
            buildInput("Opening Time (HHMM)", openingController),
            buildInput("Closing Time (HHMM)", closingController),
            buildInput("Busiest Hour (1200)", busiestController),
            buildInput("Rating (1–5)", ratingController),
            buildInput("Offer (true/false)", offerController),
            buildInput("Owner UID (read-only)", ownerController, readOnly: true),

            const SizedBox(height: 30),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 214, 145, 104),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onPressed: saveChanges,
              child: const Text(
                "Save Changes",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInput(String label, TextEditingController controller,
      {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
