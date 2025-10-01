import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moviles/viewmodels/restaurant_form_viewmodel.dart';

class RestaurantFormPage extends StatelessWidget {
  final String restaurantId;
  const RestaurantFormPage({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RestaurantFormViewModel(restaurantId)..loadData(),
      child: Consumer<RestaurantFormViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
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
                key: vm.formKey,
                child: ListView(
                  children: [
                    ...vm.generateFormFields(),

                    const SizedBox(height: 16),

                    SwitchListTile(
                      title: const Text("Has Offer?"),
                      value: vm.hasOffer,
                      onChanged: vm.toggleOffer,
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () {
                        if (vm.formKey.currentState!.validate()) {
                          vm.saveRestaurantInfo(context);
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
        },
      ),
    );
  }
}
