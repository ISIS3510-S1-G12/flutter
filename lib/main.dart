import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:moviles/repositories/review_repository.dart';
import 'package:moviles/viewmodels/review_viewmodel.dart';
import 'firebase_options.dart';

import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';

import 'package:hive_flutter/hive_flutter.dart';

import 'services/analytics_service.dart';
import 'services/location_permission_service.dart';

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
import 'package:moviles/views/pages/users_page.dart';

final FirebaseInAppMessaging fiam = FirebaseInAppMessaging.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Firebase initialized: ${app.name}');

  await Hive.initFlutter();
  await Hive.openBox('review_cache'); //  Caja donde guardamos stats de reseñas
  await Hive.openBox('local_reviews'); //  Reseñas offline sin conexión
  await Hive.openBox('user_reviews_cache'); //  Historial de usuario cacheado
  await Hive.openBox('favoritesBox');   // para favoritos del usuario

  await Hive.openBox('pendingRegistrations'); // para registros pendientes
  await Hive.openBox('favorites_offline');
  await Hive.openBox('visits_offline');


  final analyticsService = AnalyticsService();
  await analyticsService.init();

  final locationService = LocationPermissionService();
  await locationService.requestAndLogPermission();

  runApp(Sumaq(analyticsService: analyticsService));
}

class Sumaq extends StatelessWidget {
  const Sumaq({super.key, required this.analyticsService});

  final AnalyticsService analyticsService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel(AuthRepository())),
        ChangeNotifierProvider(create: (_) => UserViewModel(UserRepository())),
        ChangeNotifierProvider(create: (_) => OfferViewModel(OfferRepository())),
        ChangeNotifierProvider(
          create: (_) => RestaurantViewModel(
            RestaurantRepository(),
            UserRepository(),
            OfferRepository(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => VisitViewModel(VisitsRepository())),
        ChangeNotifierProvider(
          create: (_) => ReviewViewModel(
            ReviewRepository(),
           
          ),
        ),
        
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SUMAQ',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
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
