import 'package:flutter/material.dart';
import 'package:moviles/views/widget/login_widget.dart';

class RestaurantLogin extends StatelessWidget {
  const RestaurantLogin({super.key});

    @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.white,
      title: Text(""),
      surfaceTintColor: Colors.white,
    ),
    backgroundColor: Colors.white,
    body:SingleChildScrollView(
      child: Center(
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image(image: AssetImage("images/483891256-e6bd4888-8904-4028-911f-dff62cc98965.png"), height: MediaQuery.of(context).size.height * 0.25),
          Text("WELCOME!", style: TextStyle(color: Color.fromARGB(255,39, 111, 121), fontSize:40, fontWeight: FontWeight.bold)),
          Padding(padding: EdgeInsets.symmetric(vertical: 16.0)),
            const LoginWidget(
              accentColor: Color.fromARGB(255,39, 111, 121),
            )
          ],
      ),
    ),
  ),
  );
  }
}