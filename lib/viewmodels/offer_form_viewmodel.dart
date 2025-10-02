import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moviles/models/offer.dart';
import 'package:moviles/repositories/offer_repository.dart';

class OfferFormViewModel extends ChangeNotifier {
  final String restaurantId;
  final formKey = GlobalKey<FormState>();
  final OfferRepository _repository = OfferRepository();

  // Controllers
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final discountController = TextEditingController();
  final tagsController = TextEditingController();

  // Imagen
  File? imageFile;
  String? imageUrl;

  // Fechas
  DateTime? validFrom;
  DateTime? validTo;

  bool isSubmitting = false;

  OfferFormViewModel(this.restaurantId, {Offer? offer}) {
    if (offer != null) {
      titleController.text = offer.title;
      descriptionController.text = offer.description;
      discountController.text = offer.discountPercentage.toString();
      tagsController.text = offer.tags?.join(", ") ?? ""; // ✅ null-safe
      imageUrl = offer.image;
      validFrom = offer.validFrom;
      validTo = offer.validTo;
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      imageFile = File(picked.path);
      notifyListeners();
    }
  }

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

  Future<void> saveOffer(BuildContext context, {Offer? editingOffer}) async {
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
        id: editingOffer?.id ?? '',
        restaurantId: restaurantId,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        discountPercentage: discount,
        image: imageUrl,
        tags: tags.isEmpty ? null : tags, // ✅ null si no hay
        validFrom: validFrom,
        validTo: validTo,
        createdAt: editingOffer?.createdAt ?? DateTime.now(), // ✅ nunca null
      );

      if (editingOffer == null) {
        await _repository.createOffer(offer, image: imageFile);
      } else {
        await _repository.updateOffer(offer, image: imageFile);
      }

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
    tagsController.dispose();
    super.dispose();
  }
}
