import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../viewmodels/auth_viewmodel.dart';
import '../pages/restaurant/restaurant_form_page.dart';
import '../pages/user/user_form_page.dart';

class RegisterWidget extends StatefulWidget {
  final Color accentColor;
  final String who;
  final void Function(String userId)? onRegisterSuccess;

  const RegisterWidget({
    super.key,
    required this.accentColor,
    required this.who,
    this.onRegisterSuccess,
  });

  @override
  State<RegisterWidget> createState() => _RegisterWidgetState();
}

class _RegisterWidgetState extends State<RegisterWidget> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                  // Name
                  SizedBox(
                    height: 70,
                    width: 200,
                    child: TextFormField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 15),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'Name',
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(18.0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: widget.accentColor, width: 2.0),
                          borderRadius: const BorderRadius.all(Radius.circular(18.0)),
                        ),
                      ),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your Name';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Email
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
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: widget.accentColor, width: 2.0),
                          borderRadius: const BorderRadius.all(Radius.circular(18.0)),
                        ),
                      ),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your Email';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Password
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
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: widget.accentColor, width: 2.0),
                          borderRadius: const BorderRadius.all(Radius.circular(18.0)),
                        ),
                      ),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your Password';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Confirm Password
                  SizedBox(
                    height: 70,
                    width: 200,
                    child: TextFormField(
                      controller: _confirmPasswordController,
                      style: const TextStyle(fontSize: 15),
                      textAlign: TextAlign.center,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Confirm Password',
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(18.0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: widget.accentColor, width: 2.0),
                          borderRadius: const BorderRadius.all(Radius.circular(18.0)),
                        ),
                      ),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your Password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Register button
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        if (!authVM.isOnline) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("No internet connection. Try again later."),
                            ),
                          );
                          return;
                        }

                        if (_passwordController.text != _confirmPasswordController.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Passwords do not match")),
                          );
                          return;
                        }

                        try {
                          await authVM.register(
                            widget.who,
                            _nameController.text.trim(),
                            _emailController.text.trim(),
                            _passwordController.text.trim(),
                          );

                          if (authVM.error == null) {
                            final uid = FirebaseAuth.instance.currentUser?.uid;

                            if (uid != null) {
                              if (widget.who == "restaurant") {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RestaurantFormPage(
                                      restaurantId: uid,
                                      initialName: _nameController.text.trim(),
                                      initialEmail: _emailController.text.trim(),
                                    ),
                                  ),
                                );
                              } else if (widget.who == "user") {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UserFormPage(
                                      userId: uid,
                                      initialName: _nameController.text.trim(),
                                      initialEmail: _emailController.text.trim(),
                                    ),
                                  ),
                                );
                              }
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Register failed: ${authVM.error}")),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: $e")),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      minimumSize: const Size(200, 50),
                    ),
                    child: const Text(
                      "Register",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                ],
              ),
            ),
            // Banner offline
            if (!authVM.isOnline)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.red,
                  padding: const EdgeInsets.all(8),
                  child: const SafeArea(
                    child: Text(
                      "Offline mode: Internet not available",
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
