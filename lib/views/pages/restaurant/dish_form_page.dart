import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:moviles/models/dish.dart';
import 'package:moviles/viewmodels/dish_form_viewmodel.dart';

class DishFormPage extends StatefulWidget {
  final String restaurantId;
  final Dish? dish;

  const DishFormPage({super.key, required this.restaurantId, this.dish});

  @override
  State<DishFormPage> createState() => _DishFormPageState();
}

class _DishFormPageState extends State<DishFormPage> {
  bool _isDialogShowing = false;

  Future<bool> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    print('>>> Connectivity result: $result');
    return result != ConnectivityResult.none;
  }

  void _showOfflineDialog(BuildContext context, DishFormViewModel vm) {
    print('>>> Intentando mostrar diálogo offline...');
    if (_isDialogShowing) {
      print('>>> Diálogo ya visible, se cancela');
      return;
    }
    _isDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false, // obliga a decidir
      builder: (dialogContext) {
        print('>>> Mostrando diálogo offline en pantalla');
        return AlertDialog(
          title: const Text("Without connection"),
          content: const Text("You don’t have connection."),
          actions: [
            TextButton(
              onPressed: () async {
                print('>>> Usuario eligió "Guardar de todas formas"');
                Navigator.pop(dialogContext);
                _isDialogShowing = false;

                // Usa contexto raíz (no del diálogo)
                final rootContext = Navigator.of(context, rootNavigator: true).context;
                await vm.save(rootContext);
              },
              child: const Text("Guardar de todas formas"),
            ),
            TextButton(
              onPressed: () {
                print('>>> Usuario canceló el guardado offline');
                Navigator.pop(dialogContext);
                _isDialogShowing = false;
              },
              child: const Text("Cancelar"),
            ),
          ],
        );
      },
    ).then((_) {
      print('>>> Diálogo cerrado');
      _isDialogShowing = false;
    });
  }

  Future<void> _handleSave(BuildContext context, DishFormViewModel vm) async {
    print('>>> Presionó Save, verificando conectividad...');
    final isOnline = await _checkConnectivity();
    print('>>> Resultado conectividad: ${isOnline ? "ONLINE" : "OFFLINE"}');

    if (isOnline) {
      print('>>> Guardando en modo ONLINE...');
      await vm.save(context);
    } else {
      print('>>> Guardando en modo OFFLINE, mostrando diálogo...');
      _showOfflineDialog(context, vm);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          DishFormViewModel(restaurantId: widget.restaurantId, dish: widget.dish),
      child: Consumer<DishFormViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(vm.dish != null ? "Edit Dish" : "New Dish"),
              backgroundColor: const Color.fromARGB(255, 39, 111, 121),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: vm.formKey,
                child: ListView(
                  children: [
                    // Nombre
                    TextFormField(
                      initialValue: vm.name,
                      decoration: const InputDecoration(labelText: "Dish Name"),
                      validator: (value) =>
                          value == null || value.isEmpty ? "Enter a name" : null,
                      onSaved: (value) => vm.name = value!,
                    ),

                    // Precio
                    TextFormField(
                      initialValue: vm.price != 0.0 ? vm.price.toString() : '',
                      decoration: const InputDecoration(labelText: "Price"),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value == null || double.tryParse(value) == null
                              ? "Enter a valid price"
                              : null,
                      onSaved: (value) => vm.price = double.parse(value!),
                    ),

                    // Rating
                    TextFormField(
                      initialValue: vm.rating != 0 ? vm.rating.toString() : '',
                      decoration:
                          const InputDecoration(labelText: "Rating (1-5)"),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final n = int.tryParse(value ?? '');
                        if (n == null || n < 1 || n > 5) return "Enter 1-5";
                        return null;
                      },
                      onSaved: (value) => vm.rating = int.parse(value!),
                    ),

                    // Descripción
                    TextFormField(
                      initialValue: vm.description,
                      decoration:
                          const InputDecoration(labelText: "Description"),
                      onSaved: (value) => vm.description = value ?? '',
                    ),

                    // Dish Type
                    DropdownButtonFormField<String>(
                      value: vm.dishType.isNotEmpty ? vm.dishType : null,
                      decoration: const InputDecoration(labelText: "Dish Type"),
                      items: const [
                        DropdownMenuItem(value: "main", child: Text("Main")),
                        DropdownMenuItem(value: "drink", child: Text("Drink")),
                        DropdownMenuItem(
                            value: "dessert", child: Text("Dessert")),
                      ],
                      onChanged: vm.updateDishType,
                    ),

                    // Tags
                    TextFormField(
                      initialValue: vm.dishesTags.join(", "),
                      decoration: const InputDecoration(
                          labelText: "Tags (comma separated)"),
                      onSaved: (value) => vm.dishesTags = value!
                          .split(',')
                          .map((tag) => tag.trim())
                          .where((tag) => tag.isNotEmpty)
                          .toList(),
                    ),

                    const SizedBox(height: 16),

                    // Imagen
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: vm.pickImage,
                          icon: const Icon(Icons.image),
                          label: const Text("Pick Image"),
                        ),
                        const SizedBox(width: 10),
                        if (vm.imageFile != null)
                          Expanded(
                            child: Image.file(
                              vm.imageFile!,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          )
                        else if (vm.imageUrl.isNotEmpty)
                          Expanded(
                            child: Image.network(
                              vm.imageUrl,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image_not_supported, size: 64),
                            ),
                          )
                        else
                          const Text("No image selected"),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Botón guardar
                    ElevatedButton(
                      onPressed: () => _handleSave(context, vm),
                      child: const Text("Save"),
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
