import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../views/pages/restaurant/restaurant_home_page.dart';

class RestaurantFormViewModel extends ChangeNotifier {
  final String restaurantId;
  final formKey = GlobalKey<FormState>();

  bool isLoading = true;
  bool hasOffer = false;
  final Map<String, TextEditingController> controllers = {};

  RestaurantFormViewModel(this.restaurantId);

  Future<void> loadData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("Restaurants")
          .doc(restaurantId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        data.forEach((key, value) {
          if (key == "offer") {
            hasOffer = value == true;
          } else {
            controllers[key] = TextEditingController(text: value.toString());
          }
        });
      }
    } catch (e) {
      debugPrint("Error al cargar datos: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<Widget> generateFormFields() {
    return controllers.keys.map((key) {
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

  void toggleOffer(bool value) {
    hasOffer = value;
    notifyListeners();
  }

  Future<void> saveRestaurantInfo(BuildContext context) async {
    try {
      final dataToSave = <String, dynamic>{};
      controllers.forEach((key, controller) {
        dataToSave[key] = key.contains("time")
            ? int.tryParse(controller.text) ?? 0
            : controller.text;
      });
      dataToSave["offer"] = hasOffer;

      await FirebaseFirestore.instance
          .collection("Restaurants")
          .doc(restaurantId)
          .set({
        ...dataToSave,
        "role": "restaurant",
        "updated_at": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => RestaurantHomePage(restaurantId: restaurantId)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar: $e")),
      );
    }
  }
}
