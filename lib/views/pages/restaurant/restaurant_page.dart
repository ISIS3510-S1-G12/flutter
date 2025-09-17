import 'package:flutter/material.dart';
import 'package:moviles/views/pages/restaurant/lyr/restaurant_login.dart';
import 'package:moviles/views/pages/restaurant/lyr/restaurant_register.dart';

class RestaurantPage extends StatelessWidget {
  const RestaurantPage({super.key});

    @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      title: Text(""),
      surfaceTintColor: Colors.white,
    ),
    body: SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(image: AssetImage("images/483891256-e6bd4888-8904-4028-911f-dff62cc98965.png"), height: MediaQuery.of(context).size.height * 0.25),
            Text("WELCOME!", style: TextStyle(color: Color.fromARGB(255,41,112,122), fontSize:40, fontWeight: FontWeight.bold)),
          Padding(padding: EdgeInsets.symmetric(vertical: 16.0)),
          ElevatedButton(onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RestaurantLogin()),
            );
          }, 
                    style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(255,107,184,194), minimumSize: Size(200,50)),
                    child: Text("Login", style: TextStyle(color: Colors.white, fontSize: 20))),
          Padding(padding: EdgeInsets.symmetric(vertical: 16.0)),
          ElevatedButton(onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RestaurantRegister()),
            );
          }, 
                    style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(255,39,111,121), minimumSize: Size(200,50)), 
                    child: Text("Register", style: TextStyle(color: Colors.white, fontSize: 20))),
        ],
      ),
    ),
  ),
  );
}
}