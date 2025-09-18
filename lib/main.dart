import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Tus imports
import 'package:moviles/views/pages/users_page.dart';
import 'package:moviles/repositories/auth_repository.dart';
import 'package:moviles/repositories/user_repository.dart';
import 'package:moviles/viewmodels/auth_viewmodel.dart';
import 'package:moviles/viewmodels/user_viewmodel.dart';




void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const Sumaq());
}

class Sumaq extends StatelessWidget {
  const Sumaq({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Inyectamos los viewmodels en la app
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(AuthRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => UserViewModel(UserRepository()),
        ),
      ],
      child: MaterialApp(
        title: 'SUMAQ',
        routes: {
          '/pages/users.dart': (context) => const UsersPage(),
        },
        initialRoute: '/pages/users.dart',
      ),
    );
  }
}
