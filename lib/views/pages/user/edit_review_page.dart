// lib/views/pages/user/edit_review_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moviles/viewmodels/review_viewmodel.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:async';


class EditReviewPage extends StatefulWidget {
  final String reviewId;
  final String restaurantId;
  final String initialComment;
  final int initialStars;
  final String? initialImageUrl;

  const EditReviewPage({
    super.key,
    required this.reviewId,
    required this.restaurantId,
    required this.initialComment,
    required this.initialStars,
    this.initialImageUrl,
  });

  @override
  State<EditReviewPage> createState() => _EditReviewPageState();
}

class _EditReviewPageState extends State<EditReviewPage> {
  final formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  late TextEditingController commentCtrl;
  late double rating;

  File? newImage;

  bool isConnected = true;
  StreamSubscription<bool>? _connSub;

  @override
  void initState() {
    super.initState();

    commentCtrl = TextEditingController(text: widget.initialComment);
    rating = widget.initialStars.toDouble();

    /// 🔵 MICRO OPTIMIZACIÓN:
    /// No uses setState dentro de build → solo escucha fuera del builder
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ReviewViewModel>();
      _connSub = vm.connectivityStream.listen((status) {
        if (mounted) {
          if (!status) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "No connection: review cannot be saved right now.",
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
          setState(() => isConnected = status);
        }
      });
    });
  }

  @override
  void dispose() {
    commentCtrl.dispose();
    _connSub?.cancel();
    super.dispose();
  }

  Future<void> pickImage() async {
    final pick = await picker.pickImage(source: ImageSource.camera);
    if (pick != null) {
      setState(() {
        newImage = File(pick.path);
      });
    }
  }

  Future<String?> uploadImageIfNeeded() async {
    if (newImage == null) return widget.initialImageUrl;

    final ref = FirebaseStorage.instance
        .ref()
        .child("reviews/${widget.reviewId}.jpg");

    await ref.putFile(newImage!);
    return await ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Reseña"),
        backgroundColor: const Color.fromARGB(255, 121, 39, 101),
      ),

      /// 🔵 OPTIMIZACIÓN:
      /// Sólo escucha los valores QUE CAMBIAN (isLoading, infoMessage)
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: formKey,
                child: ListView(
                  children: [
                    Slider(
                      value: rating,
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: rating.toString(),
                      onChanged: (v) => setState(() => rating = v),
                    ),

                    TextFormField(
                      controller: commentCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: "Edita tu comentario",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? "El comentario no puede estar vacío"
                          : null,
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      onPressed: pickImage,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Cambiar foto"),
                    ),
                    const SizedBox(height: 10),

                    if (newImage != null)
                      Image.file(newImage!, height: 150, fit: BoxFit.cover)
                    else if (widget.initialImageUrl != null)
                      Image.network(
                        widget.initialImageUrl!,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 🔵 OPTIMIZACIÓN CRUCIAL:
            /// Solo el botón escucha a vm.isLoading
            Selector<ReviewViewModel, bool>(
              selector: (_, vm) => vm.isLoading,
              builder: (context, isLoading, _) {
                if (isLoading) {
                  return const CircularProgressIndicator();
                }

                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 121, 39, 101),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: !isConnected
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          final vm = context.read<ReviewViewModel>();
                          final imageUrl = await uploadImageIfNeeded();

                          await vm.updateReview(
                            reviewId: widget.reviewId,
                            restaurantId: widget.restaurantId,
                            comment: commentCtrl.text.trim(),
                            stars: rating.toInt(),
                            imageUrl: imageUrl,
                          );

                          if (vm.infoMessage != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(vm.infoMessage!),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                            vm.infoMessage = null;
                          }

                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                  child: const Text(
                    "Save Changes",
                    style: TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
