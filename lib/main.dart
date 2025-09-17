import 'package:flutter/material.dart';
import 'package:moviles/views/pages/users_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Sumaq());
}

class Sumaq extends StatelessWidget {
  const Sumaq({super.key});



  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SUMAQ',
      routes: {
        '/pages/users.dart': (context) => const UsersPage(),
      },
      initialRoute: '/pages/users.dart',
    );
  }
}