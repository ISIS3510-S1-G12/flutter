import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class RestaurantEditForm extends StatefulWidget {
  final String restaurantId;

  const RestaurantEditForm({super.key, required this.restaurantId});

  @override
  State<RestaurantEditForm> createState() => _RestaurantEditFormState();
}

class _RestaurantEditFormState extends State<RestaurantEditForm> {
  bool loading = true;

  // Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final typeController = TextEditingController();
  final openingController = TextEditingController();
  final closingController = TextEditingController();
  final busiestController = TextEditingController(); // string por simplicidad
  final ratingController = TextEditingController();
  final offerController = TextEditingController(); // se manejará como Sí/No
  final ownerController = TextEditingController();

  File? newImage;
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    loadRestaurantData();
  }

  Future<void> loadRestaurantData() async {
    print("Loading restaurant data...");

    final doc = await FirebaseFirestore.instance
        .collection("restaurants")
        .doc(widget.restaurantId)
        .get();

    if (!doc.exists) {
      print("Restaurant NOT FOUND");
      return;
    }

    final data = doc.data()!;
    print("Restaurant data loaded: $data");

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

    setState(() {
      loading = false;
    });

    print("Finished loading restaurant");
  }

  Future selectImage() async {
    print("Opening gallery...");

    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      print("Image selected: ${picked.path}");
      setState(() {
        newImage = File(picked.path);
      });
    } else {
      print("No image selected");
    }
  }

  Future<String?> uploadImage() async {
    if (newImage == null) {
      print("No new image selected");
      return imageUrl;
    }

    print("Uploading new restaurant image...");

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child("restaurants/${widget.restaurantId}.jpg");

      await ref.putFile(newImage!);
      final url = await ref.getDownloadURL();
      print("Uploaded: $url");
      return url;
    } catch (e) {
      print("Image upload error: $e");
      return imageUrl;
    }
  }

  Future<void> saveChanges() async {
    print("Saving restaurant changes...");

    final uploadedUrl = await uploadImage();

    final updateData = {
      "name": nameController.text,
      "email": emailController.text,
      "address": addressController.text,
      "typeOfFood": typeController.text,
      "opening_time": int.tryParse(openingController.text) ?? 0,
      "closing_time": int.tryParse(closingController.text) ?? 0,
      "rating": int.tryParse(ratingController.text) ?? 0,
      "offer": offerController.text.toLowerCase() == "true" ||
          offerController.text.toLowerCase() == "yes",
      "busiest_hours": {"1200": busiestController.text},
      "imageUrl": uploadedUrl ?? "",
      "updated_at": DateTime.now(),
    };

    print(updateData);

    await FirebaseFirestore.instance
        .collection("restaurants")
        .doc(widget.restaurantId)
        .update(updateData);

    print("Restaurant updated!");

    Navigator.pop(context);
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
                        ? NetworkImage(imageUrl!) as ImageProvider
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
