import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WriteReviewPage extends StatefulWidget {
  final String restaurantId;

  const WriteReviewPage({super.key, required this.restaurantId});

  @override
  State<WriteReviewPage> createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends State<WriteReviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _reviewController = TextEditingController();
  double _rating = 3.0;

  bool _loading = false;

  File? _imageFile; // 📸 Foto local
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("Usuario no autenticado");
      }

      // 🚨 Aquí solo se guarda texto y estrellas
      await FirebaseFirestore.instance.collection("Reviews").add({
        "restaurant_id": FirebaseFirestore.instance
            .collection("Restaurants")
            .doc(widget.restaurantId),
        "user_id": FirebaseFirestore.instance
            .collection("Users")
            .doc(user.uid),
        "stars": _rating.toInt(),
        "comment": _reviewController.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
        // "photoUrl": null // ⚡ Más adelante lo puedes usar si activas Storage
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

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Escribir Reseña"),
        backgroundColor: const Color.fromARGB(255, 121, 39, 101),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ⭐ Rating slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Calificación:", style: TextStyle(fontSize: 16)),
                  Text("${_rating.toStringAsFixed(1)} ⭐"),
                ],
              ),
              Slider(
                value: _rating,
                min: 1,
                max: 5,
                divisions: 4,
                label: _rating.toString(),
                onChanged: (val) => setState(() => _rating = val),
              ),
              const SizedBox(height: 20),

              // 📝 Comentario
              TextFormField(
                controller: _reviewController,
                decoration: const InputDecoration(
                  labelText: "Escribe tu comentario",
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Por favor escribe un comentario";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 📸 Botón cámara
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text("Tomar foto"),
              ),

              const SizedBox(height: 10),

              // 👀 Vista previa de la foto
              if (_imageFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _imageFile!,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),

              const Spacer(),

              // 🔘 Botón enviar
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 121, 39, 101),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      icon: const Icon(Icons.send),
                      label: const Text("Enviar Reseña"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
