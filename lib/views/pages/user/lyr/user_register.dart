import 'package:flutter/material.dart';
import 'package:moviles/views/widget/register_widget.dart';

class UserRegister extends StatelessWidget {
  const UserRegister({super.key});

    @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.white,
      title: Text(""),
      surfaceTintColor: Colors.white,
    ),
    backgroundColor: Colors.white,
    body: SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(image: AssetImage("images/483891256-e6bd4888-8904-4028-911f-dff62cc98965.png"), height: MediaQuery.of(context).size.height * 0.25),
            Text("WELCOME!", style: TextStyle(color: Color.fromARGB(255,121, 39, 101), fontSize:40, fontWeight: FontWeight.bold)),
          Padding(padding: EdgeInsets.symmetric(vertical: 16.0)),
          const RegisterWidget(
              accentColor: Color.fromARGB(255,121, 39, 101),
          ),
        ],
      ),
    ),
  ),
);
  }
}