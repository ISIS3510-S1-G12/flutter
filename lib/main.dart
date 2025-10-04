import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:moviles/views/pages/users_page.dart';
import 'package:moviles/repositories/auth_repository.dart';
import 'package:moviles/repositories/user_repository.dart';
import 'package:moviles/repositories/offer_repository.dart';
import 'package:moviles/repositories/restaurant_repository.dart';
import 'package:moviles/viewmodels/auth_viewmodel.dart';
import 'package:moviles/viewmodels/user_viewmodel.dart';
import 'package:moviles/viewmodels/offer_viewmodel.dart';
import 'package:moviles/viewmodels/restaurant_viewmodel.dart';
import 'services/analytics_service.dart';

import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';

// Instancia global de Firebase In-App Messaging
final FirebaseInAppMessaging fiam = FirebaseInAppMessaging.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  final app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Firebase initialized: ${app.name}');

  // Inicializar analytics
  final analyticsService = AnalyticsService();
  analyticsService.init();

  runApp(const Sumaq());
}

class Sumaq extends StatelessWidget {
  const Sumaq({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(AuthRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => UserViewModel(UserRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => OfferViewModel(OfferRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => RestaurantViewModel(RestaurantRepository(),UserRepository(),OfferRepository()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SUMAQ',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          useMaterial3: true,
        ),
        routes: {
          '/users': (context) => const UsersPage(),
        },
        initialRoute: '/users',
      ),
    );
  }
}
