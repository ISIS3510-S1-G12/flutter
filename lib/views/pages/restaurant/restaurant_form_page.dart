import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moviles/views/pages/restaurant/restaurant_home_page.dart';

class RestaurantFormPage extends StatefulWidget {
  final String restaurantId;
  const RestaurantFormPage({super.key, required this.restaurantId});

  @override
  State<RestaurantFormPage> createState() => _RestaurantFormPageState();
}

class _RestaurantFormPageState extends State<RestaurantFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;

  final Map<String, dynamic> restaurantFields = {
    "name": "",
    "typeOfFood": "",
    "address": "",
    "email": "",
    "rating": 0.0,
    "offer": "",
    "imageUrl": "",
    "location": "",
    "opening_time": "",
    "closing_time": "",
  };

  final Map<String, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();
    restaurantFields.forEach((key, value) {
      controllers[key] = TextEditingController();
    });
    _loadExistingData();
  }

  @override
  void dispose() {
    controllers.forEach((_, c) => c.dispose());
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("Restaurants")
          .doc(widget.restaurantId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        data.forEach((key, value) {
          if (!controllers.containsKey(key)) {
            controllers[key] = TextEditingController();
          }
          controllers[key]!.text = value.toString();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error al cargar datos: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  List<Widget> generateFormFields() {
    return restaurantFields.keys.map((key) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: TextFormField(
          controller: controllers[key],
          decoration: InputDecoration(
            labelText: key.replaceAll("_", " ").toUpperCase(),
          ),
          keyboardType: key.contains("time")
              ? TextInputType.number
              : TextInputType.text,
          validator: (value) =>
              (value == null || value.isEmpty) ? "Required" : null,
        ),
      );
    }).toList();
  }

  Future<void> _saveRestaurantInfo() async {
    try {
      final dataToSave = <String, dynamic>{};
      controllers.forEach((key, controller) {
        dataToSave[key] =
            key.contains("time") ? int.tryParse(controller.text) ?? 0 : controller.text;
      });

      await FirebaseFirestore.instance
          .collection("Restaurants")
          .doc(widget.restaurantId)
          .set({
        ...dataToSave,
        "role": "restaurant",
        "updated_at": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => RestaurantHomePage(restaurantId: widget.restaurantId)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error al guardar: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Restaurant Info"),
        backgroundColor: const Color.fromARGB(255, 39, 111, 121),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ...generateFormFields(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _saveRestaurantInfo();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 39, 111, 121),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  "Save and Continue",
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
