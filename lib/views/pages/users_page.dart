import 'package:flutter/material.dart';
import 'package:moviles/views/pages/restaurant/restaurant_page.dart';
import 'package:moviles/views/pages/user/user_page.dart';


class UsersPage extends StatelessWidget {
  const UsersPage({super.key});
  

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
            Text("SUMAQ", style: TextStyle(color: Color.fromARGB(255, 124, 46, 35), fontSize:40, fontWeight: FontWeight.bold)),
            Text("Hii! are you a...", style: TextStyle(color: Color.fromARGB(255, 124, 46, 35), fontSize:30, fontWeight: FontWeight.bold)),
            Padding(padding: EdgeInsets.symmetric(vertical: 16.0)),
            ElevatedButton(onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) => const UserPage(),
                ),
              );
                }, 
                      style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(255,121,39,101), minimumSize: Size(200,50)),
                      child: Text("User", style: TextStyle(color: Colors.white, fontSize: 20))),
            Padding(padding: EdgeInsets.symmetric(vertical: 16.0)),
            ElevatedButton(onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const RestaurantPage(),
                ),
              );
            }, 
                      style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(255,39,111,121), minimumSize: Size(200,50)), 
                      child: Text("Restaurant", style: TextStyle(color: Colors.white, fontSize: 20))),
          ],
        ),
      ),
  ),
  );
}
}