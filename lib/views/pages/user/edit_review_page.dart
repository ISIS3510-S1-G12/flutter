import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moviles/viewmodels/review_viewmodel.dart';
import 'package:firebase_storage/firebase_storage.dart';

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

  bool isConnected = true; // control local de conexión

  @override
  void initState() {
    super.initState();
    commentCtrl = TextEditingController(text: widget.initialComment);
    rating = widget.initialStars.toDouble();

    // suscribirse al stream de conexión
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ReviewViewModel>();
      vm.connectivityStream.listen((status) {
        setState(() {
          isConnected = status;
        });
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
      });
    });
  }

  @override
  void dispose() {
    commentCtrl.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final pick = await picker.pickImage(source: ImageSource.camera);
    if (pick != null) setState(() => newImage = File(pick.path));
  }

  Future<String?> uploadImageIfNeeded() async {
    if (newImage == null) return widget.initialImageUrl;
    final ref = FirebaseStorage.instance.ref().child("reviews/${widget.reviewId}.jpg");
    await ref.putFile(newImage!);
    return await ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Editar Reseña"),
            backgroundColor: const Color.fromARGB(255, 121, 39, 101),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: formKey,
              child: Column(
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
                    Image.network(widget.initialImageUrl!, height: 150, fit: BoxFit.cover),
                  const Spacer(),

                  vm.isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 121, 39, 101),
                            minimumSize: const Size.fromHeight(50),
                          ),
                          onPressed: !isConnected
                              ? null // deshabilita si no hay conexión
                              : () async {
                                  if (!formKey.currentState!.validate()) return;

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
                                    await Future.delayed(const Duration(milliseconds: 500));
                                  }

                                  Navigator.pop(context);
                                },
                          child: const Text(
                            "Save Changes",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
