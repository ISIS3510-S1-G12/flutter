import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Tus imports
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Firebase initialized: ${app.name}');
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
          create: (_) => RestaurantViewModel(RestaurantRepository()),
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
          '/pages/users.dart': (context) => const UsersPage(),
        },
        initialRoute: '/pages/users.dart',
      ),
    );
  }
}
