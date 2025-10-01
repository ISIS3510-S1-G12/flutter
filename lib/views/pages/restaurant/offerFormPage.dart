import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moviles/viewmodels/offer_form_viewmodel.dart';


class OfferFormPage extends StatelessWidget {
  final String restaurantId;
  const OfferFormPage({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OfferFormViewModel(restaurantId),
      child: Consumer<OfferFormViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Create Offer"),
              backgroundColor: const Color.fromARGB(255, 39, 111, 121),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: vm.formKey,
                child: ListView(
                  children: [
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
                    TextFormField(
                      controller: vm.imageController,
                      decoration: const InputDecoration(
                        labelText: "Image URL (optional)",
                        hintText: "https://...",
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: vm.tagsController,
                      decoration: const InputDecoration(
                        labelText: "Tags (comma separated)",
                        hintText: "Ej: big, cheap, weekend",
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(vm.validFrom == null
                              ? "Valid from: Not set"
                              : "Valid from: ${vm.validFrom!.toLocal()}".split(" ")[0]),
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
                          child: Text(vm.validTo == null
                              ? "Valid to: Not set"
                              : "Valid to: ${vm.validTo!.toLocal()}".split(" ")[0]),
                        ),
                        TextButton(
                          onPressed: () => vm.pickDate(context, isFrom: false),
                          child: const Text("Pick"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: vm.isSubmitting
                          ? null
                          : () => vm.saveOffer(context),
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
                          : const Text(
                              "Save Offer",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18),
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
