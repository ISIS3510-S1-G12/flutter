import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Or, if using a relative path:
import '../../viewmodels/auth_viewmodel.dart';

class RegisterWidget extends StatefulWidget {
  final Color accentColor;
  final String who;
  final void Function(String userId)? onRegisterSuccess; // ← agrega est
  
  const RegisterWidget({super.key,
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            height: 70, 
            width: 200,
            child: TextFormField(
              controller: _nameController,
              style: TextStyle(fontSize: 15),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(18.0)),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: widget.accentColor, width: 2.0),
                  borderRadius: BorderRadius.all(Radius.circular(18.0)),
                ),
                errorStyle: TextStyle(
                  fontSize: 12, 
                  height: 0.8,  
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
          const Padding(padding: EdgeInsets.symmetric(vertical: 10.0)),
          SizedBox(
            height: 70, 
            width: 200,
            child: TextFormField(
              controller: _emailController,
              style:  TextStyle(fontSize: 15),
              textAlign: TextAlign.center,
              decoration:  InputDecoration(
                hintText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(18.0)),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: widget.accentColor, width: 2.0),
                  borderRadius: BorderRadius.all(Radius.circular(18.0)),
                ),
                errorStyle: TextStyle(
                  fontSize: 12, 
                  height: 0.8,  
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
          const Padding(padding: EdgeInsets.symmetric(vertical: 10.0)),
          SizedBox(
            height: 70,
            width: 200,
            child: TextFormField(
              controller: _passwordController,
              style:  TextStyle(fontSize: 15),
              textAlign: TextAlign.center,
              obscureText: true,
              decoration:  InputDecoration(
                hintText: 'Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(18.0)),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: widget.accentColor, width: 2.0),
                  borderRadius: BorderRadius.all(Radius.circular(18.0)),
                ),
                errorStyle: TextStyle(
                  fontSize: 12,
                  height: 0.8,
                ),
              ),
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Enter your password';
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
              controller: _confirmPasswordController,
              style:  TextStyle(fontSize: 15),
              textAlign: TextAlign.center,
              obscureText: true,
              decoration:  InputDecoration(
                hintText: 'Confirm Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(18.0)),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: widget.accentColor, width: 2.0),
                  borderRadius: BorderRadius.all(Radius.circular(18.0)),
                ),
                errorStyle: TextStyle(
                  fontSize: 12,
                  height: 0.8,
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  if (_passwordController.text != _confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Passwords do not match")),
                    );
                    return;
                  }

                  try {
                    final authVM = Provider.of<AuthViewModel>(context, listen: false);
                    await authVM.register(
                      widget.who,
                      _nameController.text.trim(),
                      _emailController.text.trim(),
                      _passwordController.text.trim(),
                    );

                  } catch (e) {
                    // Handle registration error
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
          ),
        ],
      ),
    );
  }
}