import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class UserEditForm extends StatefulWidget {
  const UserEditForm({super.key});

  @override
  State<UserEditForm> createState() => _UserEditFormState();
}

class _UserEditFormState extends State<UserEditForm> {
  bool loading = true;

  // Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final budgetController = TextEditingController();
  final dietController = TextEditingController();

  File? newProfileImage;
  String? profilePictureUrl;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    print(" Loading user data...");

    final uid = FirebaseAuth.instance.currentUser!.uid;
    print(" Current UID: $uid");

    final doc = await FirebaseFirestore.instance.collection("Users").doc(uid).get();

    if (!doc.exists) {
      print(" User document NOT FOUND");
      return;
    }

    final data = doc.data()!;
    print("User data loaded: $data");

    // Precargar controllers
    nameController.text = data["name"] ?? "";
    emailController.text = data["email"] ?? "";
    passwordController.text = data["password"] ?? "";
    budgetController.text = data["preferences"]["budget"].toString();
    dietController.text = data["preferences"]["diet"] ?? "";

    profilePictureUrl = data["profile_picture"];

    // Debug prints
    print(" name: ${nameController.text}");
    print(" email: ${emailController.text}");
    print(" password: ${passwordController.text}");
    print(" budget: ${budgetController.text}");
    print(" diet: ${dietController.text}");
    print(" profile_picture: $profilePictureUrl");

    setState(() {
      loading = false;
    });

    print("Finished loading user data");
  }

  Future selectImage() async {
    print("Opening gallery...");

    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      print("📸 Image selected: ${picked.path}");
      setState(() {
        newProfileImage = File(picked.path);
      });
    } else {
      print("No image selected");
    }
  }

  Future<String?> uploadProfilePicture() async {
    if (newProfileImage == null) {
      print("No new profile image, keeping old one");
      return profilePictureUrl;
    }

    print("Uploading new profile picture...");

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseStorage.instance.ref().child("users/$uid.jpg");

    try {
      await ref.putFile(newProfileImage!);
      final url = await ref.getDownloadURL();
      print("Image uploaded: $url");
      return url;
    } catch (e) {
      print("Error uploading image: $e");
      return profilePictureUrl;
    }
  }

  Future<void> saveChanges() async {
    print(" Saving changes...");

    final uid = FirebaseAuth.instance.currentUser!.uid;

    print(" Uploading picture (if any)...");
    final uploadedUrl = await uploadProfilePicture();

    print(" Data being updated:");
    print({
      "name": nameController.text,
      "email": emailController.text,
      "password": passwordController.text,
      "preferences": {
        "budget": int.parse(budgetController.text),
        "diet": dietController.text
      },
      "profile_picture": uploadedUrl
    });

    await FirebaseFirestore.instance.collection("Users").doc(uid).update({
      "name": nameController.text,
      "email": emailController.text,
      "password": passwordController.text,
      "preferences": {
        "budget": int.parse(budgetController.text),
        "diet": dietController.text,
      },
      "profile_picture": uploadedUrl ?? "",
      "updated_at": DateTime.now(),
    });

    print("User updated successfully");

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
        title: const Text("Edit User"),
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
                backgroundImage: newProfileImage != null
                    ? FileImage(newProfileImage!)
                    : (profilePictureUrl != null && profilePictureUrl!.isNotEmpty)
                        ? NetworkImage(profilePictureUrl!)
                        : null,
                child: (newProfileImage == null &&
                        (profilePictureUrl == null || profilePictureUrl!.isEmpty))
                    ? const Icon(Icons.camera_alt, size: 40)
                    : null,
              ),
            ),

            const SizedBox(height: 8),
            const Text("Tap to change profile picture"),

            const SizedBox(height: 30),

            buildInputField("Name", nameController),
            buildInputField("Email", emailController),
            buildInputField("Password", passwordController),
            buildInputField("Budget", budgetController, type: TextInputType.number),
            buildInputField("Diet (Vegan, Keto, etc.)", dietController),

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

  Widget buildInputField(String label, TextEditingController controller,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
