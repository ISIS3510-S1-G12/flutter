import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Tus imports
import 'package:moviles/views/pages/users_page.dart';
import 'package:moviles/repositories/auth_repository.dart';
import 'package:moviles/repositories/user_repository.dart';
import 'package:moviles/repositories/offer_repository.dart';
import 'package:moviles/viewmodels/auth_viewmodel.dart';
import 'package:moviles/viewmodels/user_viewmodel.dart';
import 'package:moviles/viewmodels/offer_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('✅ Firebase initialized: ${app.name}');

  runApp(const Sumaq());
}

class Sumaq extends StatelessWidget {
  const Sumaq({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ViewModels inyectados
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(AuthRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => UserViewModel(UserRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => OfferViewModel(OfferRepository()), // 👈 ya está aquí
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SUMAQ',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          useMaterial3: true,
        ),
        // Rutas registradas
        routes: {
          '/pages/users.dart': (context) => const UsersPage(),
          // 👉 cuando tengas más páginas, añádelas aquí
        },
        initialRoute: '/pages/users.dart',
      ),
    );
  }
}
