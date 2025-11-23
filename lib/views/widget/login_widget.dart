import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../pages/user/user_home_page.dart';
import '../pages/restaurant/restaurant_home_page.dart';

class LoginWidget extends StatefulWidget {
  final Color accentColor;
  final String who;

  const LoginWidget({
    super.key,
    required this.accentColor,
    required this.who,
  });

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, _) {
        return Stack(
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    height: 70,
                    width: 200,
                    child: TextFormField(
                      controller: _emailController,
                      style: const TextStyle(fontSize: 15),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(18.0)),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: widget.accentColor, width: 2.0),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(18.0)),
                        ),
                        errorStyle:
                            const TextStyle(fontSize: 12, height: 0.8),
                      ),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your email';
                        }
                        return null;
                      },
                    ),
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 10.0)),
                  SizedBox(
                    height: 70,
                    width: 200,
                    child: TextFormField(
                      controller: _passwordController,
                      style: const TextStyle(fontSize: 15),
                      textAlign: TextAlign.center,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(18.0)),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: widget.accentColor, width: 2.0),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(18.0)),
                        ),
                        errorStyle:
                            const TextStyle(fontSize: 12, height: 0.8),
                      ),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your password';
                        }
                        return null;
                      },
                    ),
                  ), 
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final email = _emailController.text.trim();
                          final password = _passwordController.text.trim();

                          // 🔹 Si NO hay conexión → guardar login pendiente en Hive
                          if (!authVM.isOnline) {
                            await authVM.savePendingLogin(
                              who: widget.who,
                              email: email,
                              password: password,
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "No connection: login stored locally and will retry when online.",
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          // 🔹 Si hay conexión → login normal
                          try {
                            await authVM.login(
                                widget.who, email, password);

                            if (authVM.error == null) {
                              if (widget.who == "restaurant") {
                                final uid =
                                    FirebaseAuth.instance.currentUser?.uid;
                                if (uid != null) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          RestaurantHomePage(restaurantId: uid),
                                    ),
                                  );
                                }
                              } else if (widget.who == "user") {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const UserHomePage(),
                                  ),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      "Login failed: ${authVM.error}"),
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text("Error: $e")),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.accentColor,
                        minimumSize: const Size(200, 50),
                      ),
                      child: const Text(
                        "Log In",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
