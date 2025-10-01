import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moviles/models/offer.dart';
import 'package:moviles/viewmodels/offer_viewmodel.dart';

class OfferFormPage extends StatefulWidget {
  final String restaurantId;
  const OfferFormPage({super.key, required this.restaurantId});

  @override
  State<OfferFormPage> createState() => _OfferFormPageState();
}

class _OfferFormPageState extends State<OfferFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountController = TextEditingController();
  final _imageController = TextEditingController();
  final _tagsController = TextEditingController();

  DateTime? _validFrom;
  DateTime? _validTo;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    _imageController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _validFrom = picked;
        } else {
          _validTo = picked;
        }
      });
    }
  }

  Future<void> _saveOffer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final discount = double.tryParse(_discountController.text.trim()) ?? 0.0;

      final tags = _tagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Creamos el modelo Offer (id vacío porque Firestore lo crea)
      final offer = Offer(
        id: '', // Firestore generará el id
        restaurantId: widget.restaurantId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        discountPercentage: discount,
        image: _imageController.text.trim().isEmpty
            ? null
            : _imageController.text.trim(),
        tags: tags.isEmpty ? null : tags,
        validFrom: _validFrom,
        validTo: _validTo,
        createdAt: null,
      );

      // Llamamos al viewmodel para guardar
      final vm = Provider.of<OfferViewModel>(context, listen: false);
      await vm.addOffer(offer);

      if (!mounted) return;
      Navigator.pop(context, true); // regreso con éxito
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving offer: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Offer"),
        backgroundColor: const Color.fromARGB(255, 39, 111, 121),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Offer Title"),
                validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
                validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _discountController,
                decoration: const InputDecoration(labelText: "Discount (%)"),
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
                controller: _imageController,
                decoration: const InputDecoration(
                  labelText: "Image URL (optional)",
                  hintText: "https://...",
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: "Tags (comma separated)",
                  hintText: "Ej: big, cheap, weekend",
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(_validFrom == null
                        ? "Valid from: Not set"
                        : "Valid from: ${_validFrom!.toLocal()}".split(" ")[0]),
                  ),
                  TextButton(
                    onPressed: () => _pickDate(isFrom: true),
                    child: const Text("Pick"),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(_validTo == null
                        ? "Valid to: Not set"
                        : "Valid to: ${_validTo!.toLocal()}".split(" ")[0]),
                  ),
                  TextButton(
                    onPressed: () => _pickDate(isFrom: false),
                    child: const Text("Pick"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _saveOffer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 39, 111, 121),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        "Save Offer",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
