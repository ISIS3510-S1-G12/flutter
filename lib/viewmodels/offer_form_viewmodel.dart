import 'package:flutter/material.dart';
import 'package:moviles/models/offer.dart';
import 'package:moviles/viewmodels/offer_viewmodel.dart';
import 'package:provider/provider.dart';

class OfferFormViewModel extends ChangeNotifier {
  final String restaurantId;
  final formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final discountController = TextEditingController();
  final imageController = TextEditingController();
  final tagsController = TextEditingController();

  DateTime? validFrom;
  DateTime? validTo;
  bool isSubmitting = false;

  OfferFormViewModel(this.restaurantId);

  Future<void> pickDate(BuildContext context, {required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      if (isFrom) {
        validFrom = picked;
      } else {
        validTo = picked;
      }
      notifyListeners();
    }
  }

  Future<void> saveOffer(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;

    isSubmitting = true;
    notifyListeners();

    try {
      final discount = double.tryParse(discountController.text.trim()) ?? 0.0;

      final tags = tagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final offer = Offer(
        id: '',
        restaurantId: restaurantId,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        discountPercentage: discount,
        image: imageController.text.trim().isEmpty
            ? null
            : imageController.text.trim(),
        tags: tags.isEmpty ? null : tags,
        validFrom: validFrom,
        validTo: validTo,
        createdAt: null,
      );

      final vm = Provider.of<OfferViewModel>(context, listen: false);
      await vm.addOffer(offer);

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving offer: $e")),
      );
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    discountController.dispose();
    imageController.dispose();
    tagsController.dispose();
    super.dispose();
  }
}
