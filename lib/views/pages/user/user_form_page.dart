import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moviles/models/user.dart';
import 'package:moviles/repositories/user_repository.dart';

class UserFormPage extends StatefulWidget {
  final String userId;
  final User? initialUser;
  final String? initialName;
  final String? initialEmail;

  const UserFormPage({
    super.key,
    required this.userId,
    this.initialUser,
    this.initialName,
    this.initialEmail,
  });

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _dietController;
  late TextEditingController _budgetController;

  String? _profileImagePath; 

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialUser?.name ?? widget.initialName ?? "");
    _emailController =
        TextEditingController(text: widget.initialUser?.email ?? widget.initialEmail ?? "");
    _dietController = TextEditingController(
        text: widget.initialUser?.preferences["diet"] ?? "");
    _budgetController = TextEditingController(
        text: widget.initialUser?.preferences["budget"]?.toString() ?? "0");

    _profileImagePath = widget.initialUser?.profilePicture;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        _profileImagePath = pickedFile.path;
      });
    }
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    final user = User(
      id: widget.userId,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      ownerUid: widget.initialUser?.ownerUid ?? widget.userId,
      role: widget.initialUser?.role ?? "user",
      preferences: {
        "diet": _dietController.text.trim(),
        "budget": int.tryParse(_budgetController.text) ?? 0,
      },
      favoriteRestaurants: widget.initialUser?.favoriteRestaurants ?? {},
      profilePicture: _profileImagePath,
      createdAt: widget.initialUser?.createdAt ?? Timestamp.now(),
      updatedAt: Timestamp.now(),
    );

    await UserRepository().saveUser(user);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User saved successfully!")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Info")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _profileImagePath != null
                        ? (_profileImagePath!.startsWith("http")
                            ? NetworkImage(_profileImagePath!)
                            : FileImage(File(_profileImagePath!)) as ImageProvider)
                        : null,
                    child: _profileImagePath == null
                        ? const Icon(Icons.camera_alt, size: 40)
                        : null,
                  ),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                  validator: (val) =>
                      val == null || val.isEmpty ? "Enter name" : null,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                  validator: (val) =>
                      val == null || val.isEmpty ? "Enter email" : null,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _dietController,
                  decoration: const InputDecoration(labelText: "Diet"),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _budgetController,
                  decoration: const InputDecoration(labelText: "Budget"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _saveUser,
                  child: const Text("Save User"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
