import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moviles/models/offer.dart';
import 'package:moviles/viewmodels/offer_form_viewmodel.dart';

class OfferFormPage extends StatelessWidget {
  final String restaurantId;
  final Offer? editingOffer;

  const OfferFormPage({
    super.key,
    required this.restaurantId,
    this.editingOffer,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OfferFormViewModel(restaurantId, offer: editingOffer),
      child: Consumer<OfferFormViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(editingOffer == null ? "Create Offer" : "Edit Offer"),
              backgroundColor: const Color.fromARGB(255, 39, 111, 121),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: vm.formKey,
                child: ListView(
                  children: [
                    // ---- Imagen ----
                    GestureDetector(
                      onTap: vm.pickImage,
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: vm.imageFile != null
                            ? Image.file(vm.imageFile!, fit: BoxFit.cover)
                            : (vm.imageUrl != null && vm.imageUrl!.isNotEmpty)
                                ? Image.network(
                                    vm.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, _, __) =>
                                        const Icon(Icons.image_not_supported),
                                  )
                                : const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_a_photo,
                                            size: 40, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text("Tap to add image"),
                                      ],
                                    ),
                                  ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ---- Campos de texto ----
                    TextFormField(
                      controller: vm.titleController,
                      decoration: const InputDecoration(labelText: "Offer Title"),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: vm.descriptionController,
                      decoration: const InputDecoration(labelText: "Description"),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? "Required" : null,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),

                    // ---- Precio ----
                    TextFormField(
                      controller: vm.priceController,
                      decoration: const InputDecoration(labelText: "Price"),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        final p = double.tryParse(value ?? "");
                        if (p == null || p <= 0) {
                          return "Enter a valid price";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // ---- Descuento ----
                    TextFormField(
                      controller: vm.discountController,
                      decoration:
                          const InputDecoration(labelText: "Discount (%)"),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final d = double.tryParse(value ?? "");
                        if (d == null || d < 0 || d > 100) {
                          return "Enter a valid discount (0-100)";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // ---- Tags ----
                    TextFormField(
                      controller: vm.tagsController,
                      decoration: const InputDecoration(
                        labelText: "Tags (comma separated)",
                        hintText: "Eg: big, cheap, weekend",
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ---- Fechas ----
                    Row(
                      children: [
                        Expanded(
                          child: Text(vm.valid_from == null
                              ? "Valid from: Not set"
                              : "Valid from: ${vm.valid_from!.toLocal()}".split(" ")[0]),
                        ),
                        TextButton(
                          onPressed: () => vm.pickDate(context, isFrom: true),
                          child: const Text("Pick"),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(vm.valid_to == null
                              ? "Valid to: Not set"
                              : "Valid to: ${vm.valid_to!.toLocal()}".split(" ")[0]),
                        ),
                        TextButton(
                          onPressed: () => vm.pickDate(context, isFrom: false),
                          child: const Text("Pick"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ---- Botón Guardar ----
                    ElevatedButton(
                      onPressed: vm.isSubmitting
                          ? null
                          : () => vm.saveOffer(context, editingOffer: editingOffer),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 39, 111, 121),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: vm.isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              editingOffer == null
                                  ? "Save Offer"
                                  : "Update Offer",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 18),
                            ),
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
