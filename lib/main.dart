import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:moviles/views/pages/users_page.dart';
import 'package:moviles/repositories/auth_repository.dart';
import 'package:moviles/repositories/user_repository.dart';
import 'package:moviles/repositories/offer_repository.dart';
import 'package:moviles/repositories/restaurant_repository.dart';
import 'package:moviles/repositories/visits_repository.dart';
import 'package:moviles/viewmodels/auth_viewmodel.dart';
import 'package:moviles/viewmodels/user_viewmodel.dart';
import 'package:moviles/viewmodels/offer_viewmodel.dart';
import 'package:moviles/viewmodels/restaurant_viewmodel.dart';
import 'package:moviles/viewmodels/visit_viewmodel.dart';
import 'services/analytics_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';

import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:permission_handler/permission_handler.dart';

// Instancia global de Firebase In-App Messaging
final FirebaseInAppMessaging fiam = FirebaseInAppMessaging.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializar Firebase
  final app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Firebase initialized: ${app.name}');

  // Inicializar AnalyticsService
  // 2. Inicializar Firebase Analytics
  final analyticsService = AnalyticsService();
  await analyticsService.init();

  runApp(Sumaq(analyticsService: analyticsService));
  // 3. Solicitar permiso de ubicación y registrar evento en Analytics
  await _checkAndLogLocationPermission();

}

// --- Función auxiliar para manejar el permiso de ubicación ---
Future<void> _checkAndLogLocationPermission() async {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  final status = await Permission.location.request();

  String permissionStatus;
  if (status.isGranted) {
    permissionStatus = 'granted';
  } else if (status.isDenied) {
    permissionStatus = 'denied';
  } else if (status.isPermanentlyDenied) {
    permissionStatus = 'permanently_denied';
  } else {
    permissionStatus = 'unknown';
  }

  await analytics.logEvent(
    name: 'location_permission_granted',
    parameters: {'status': permissionStatus},
  );

  print('Logged location_permission_granted: $permissionStatus');
}

class Sumaq extends StatelessWidget {
  const Sumaq({super.key, required this.analyticsService});

  final AnalyticsService analyticsService;

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
          create: (_) => RestaurantViewModel(
            RestaurantRepository(),
            UserRepository(),
            OfferRepository(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => VisitViewModel(VisitsRepository()),
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
        navigatorObservers: [
          FirebaseAnalyticsObserver(analytics: analyticsService.analytics),
        ],
        initialRoute: '/users',
      ),
    );
  }
}
