import 'package:flutter/material.dart';
import 'package:moviles/viewmodels/popularity_viewmodel.dart';
import 'package:provider/provider.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class UserTopRestaurantPage extends StatelessWidget {
  const UserTopRestaurantPage({super.key});

  Future<Map<String, dynamic>?> _getRestaurantInfo(String id) async {
    final doc = await FirebaseFirestore.instance.collection('Restaurants').doc(id).get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PopularityViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurante más popular'),
        backgroundColor: Colors.orange,
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.mostVisitedRestaurantId == null
              ? const Center(
                  child: Text("No hay datos de visitas esta semana."),
                )
              : FutureBuilder<Map<String, dynamic>?>(
                  future: _getRestaurantInfo(vm.mostVisitedRestaurantId!),
                  builder: (context, snapshot) {
                    final data = snapshot.data;
                    if (data == null) {
                      return const Center(child: Text("Cargando restaurante..."));
                    }
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.orangeAccent, Colors.deepOrange],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "🏆 Restaurante más visitado esta semana",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  data['name'] ?? 'Restaurante desconocido',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "${vm.getVisitsForRestaurant(vm.mostVisitedRestaurantId!)} visitas esta semana",
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => vm.calculateWeeklyPopularity(),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
