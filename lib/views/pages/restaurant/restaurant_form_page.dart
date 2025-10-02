import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RestaurantFormPage extends StatefulWidget {
  final String restaurantId;
  final String? initialName;
  final String? initialEmail;

  const RestaurantFormPage({
    super.key,
    required this.restaurantId,
    this.initialName,
    this.initialEmail,
  });

  @override
  State<RestaurantFormPage> createState() => _RestaurantFormPageState();
}

class _RestaurantFormPageState extends State<RestaurantFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _typeOfFoodController;
  late TextEditingController _openingTimeController;
  late TextEditingController _closingTimeController;
  late TextEditingController _ratingController;

  // Nuevos controladores
  late TextEditingController _busiestOpeningController;
  late TextEditingController _busiestClosingController;

  bool _offer = false;
  File? _image;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.initialName ?? "");
    _emailController = TextEditingController(text: widget.initialEmail ?? "");
    _addressController = TextEditingController();
    _typeOfFoodController = TextEditingController();
    _openingTimeController = TextEditingController(text: "9");
    _closingTimeController = TextEditingController(text: "22");
    _ratingController = TextEditingController(text: "0.0");

    // Inicializamos los nuevos
    _busiestOpeningController = TextEditingController(text: "730");
    _busiestClosingController = TextEditingController(text: "1500");
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  Future<void> _saveRestaurant() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      String? imageUrl;
      if (_image != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child("restaurants/${widget.restaurantId}/logo.jpg");

        await storageRef.putFile(_image!);
        imageUrl = await storageRef.getDownloadURL();
      }

      final now = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance
          .collection("Restaurants")
          .doc(widget.restaurantId)
          .set({
        "name": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        "address": _addressController.text.trim(),
        "typeOfFood": _typeOfFoodController.text.trim(),
        "offer": _offer,
        "imageUrl": imageUrl ?? "",
        "opening_time": int.tryParse(_openingTimeController.text) ?? 9,
        "closing_time": int.tryParse(_closingTimeController.text) ?? 22,
        "rating": double.tryParse(_ratingController.text) ?? 0.0,

        // Nuevos campos
        "busiest_hours": {
          "opening_time": int.tryParse(_busiestOpeningController.text) ?? 730,
          "closing_time": int.tryParse(_busiestClosingController.text) ?? 1500,
        },
        "created_at": now,
        "updated_at": now,
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(" Restaurant saved successfully!")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(" Error saving restaurant: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Restaurant Info")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                  validator: (val) =>
                      val == null || val.isEmpty ? "Enter name" : null,
                ),
                const SizedBox(height: 10),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                  validator: (val) =>
                      val == null || val.isEmpty ? "Enter email" : null,
                ),
                const SizedBox(height: 10),

                // Address
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: "Address"),
                  validator: (val) =>
                      val == null || val.isEmpty ? "Enter address" : null,
                ),
                const SizedBox(height: 10),

                // Type of Food
                TextFormField(
                  controller: _typeOfFoodController,
                  decoration: const InputDecoration(labelText: "Type of food"),
                  validator: (val) =>
                      val == null || val.isEmpty ? "Enter type of food" : null,
                ),
                const SizedBox(height: 10),

                // Opening time
                TextFormField(
                  controller: _openingTimeController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: "Opening time (0-23)"),
                ),
                const SizedBox(height: 10),

                // Closing time
                TextFormField(
                  controller: _closingTimeController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: "Closing time (0-23)"),
                ),
                const SizedBox(height: 10),

                // Rating
                TextFormField(
                  controller: _ratingController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Rating (0-5)"),
                ),
                const SizedBox(height: 10),

                // Busiest Hours Opening
                TextFormField(
                  controller: _busiestOpeningController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: "Busiest Opening Time (e.g., 730)"),
                ),
                const SizedBox(height: 10),

                // Busiest Hours Closing
                TextFormField(
                  controller: _busiestClosingController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: "Busiest Closing Time (e.g., 1500)"),
                ),
                const SizedBox(height: 10),

                // Offer switch
                SwitchListTile(
                  value: _offer,
                  title: const Text("Has offer?"),
                  onChanged: (val) => setState(() => _offer = val),
                ),
                const SizedBox(height: 10),

                // Image picker
                if (_image != null) Image.file(_image!, height: 150),
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text("Pick Image"),
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveRestaurant,
                  child: const Text("Save and Continue"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
