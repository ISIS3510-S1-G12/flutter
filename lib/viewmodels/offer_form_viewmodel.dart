import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moviles/models/offer.dart';
import 'package:moviles/repositories/offer_repository.dart';

class OfferFormViewModel extends ChangeNotifier {
  final String restaurant_id; // 👈 snake_case
  final formKey = GlobalKey<FormState>();
  final OfferRepository _repository = OfferRepository();

  // Controllers
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final discountController = TextEditingController();
  final priceController = TextEditingController(); 
  final tagsController = TextEditingController();

  // Imagen
  File? imageFile;
  String? imageUrl;

  // Fechas
  DateTime? valid_from;
  DateTime? valid_to;

  bool isSubmitting = false;

  OfferFormViewModel(this.restaurant_id, {Offer? offer}) {
    if (offer != null) {
      titleController.text = offer.title;
      descriptionController.text = offer.description;
      discountController.text = offer.discount_percentage.toString();
      priceController.text = offer.price.toString(); 
      tagsController.text = offer.tags?.join(", ") ?? ""; 
      imageUrl = offer.image;
      valid_from = offer.valid_from;
      valid_to = offer.valid_to;
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
        valid_from = picked;
      } else {
        valid_to = picked;
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
      final price = double.tryParse(priceController.text.trim()) ?? 0.0; 
      final tags = tagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final offer = Offer(
        id: editingOffer?.id ?? '',
        restaurant_id: restaurant_id,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        discount_percentage: discount,
        price: price,
        image: imageUrl,
        tags: tags.isEmpty ? null : tags,
        valid_from: valid_from,
        valid_to: valid_to,
        createdAt: editingOffer?.createdAt ?? DateTime.now(),
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
    priceController.dispose(); 
    tagsController.dispose();
    super.dispose();
  }
}
