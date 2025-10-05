import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moviles/viewmodels/write_review_viewmodel.dart';

class WriteReviewPage extends StatelessWidget {
  final String restaurantId;

  const WriteReviewPage({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WriteReviewViewModel(restaurantId),
      child: Consumer<WriteReviewViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Escribir Reseña"),
              backgroundColor: const Color.fromARGB(255, 121, 39, 101),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: vm.formKey,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Calificación:",
                            style: TextStyle(fontSize: 16)),
                        Text("${vm.rating.toStringAsFixed(1)}"),
                      ],
                    ),
                    Slider(
                      value: vm.rating,
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: vm.rating.toString(),
                      onChanged: (val) {
                        vm.rating = val;
                        vm.notifyListeners();
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: vm.reviewController,
                      decoration: const InputDecoration(
                        labelText: "Escribe tu comentario",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                      validator: (val) => val == null || val.trim().isEmpty
                          ? "Por favor escribe un comentario"
                          : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: vm.pickImage,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Tomar foto"),
                    ),
                    const SizedBox(height: 10),
                    if (vm.imageFile != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          vm.imageFile!,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const Spacer(),
                    vm.loading
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                            onPressed: () => vm.submitReview(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 121, 39, 101),
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
        },
      ),
    );
  }
}