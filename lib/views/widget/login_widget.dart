import 'package:flutter/material.dart';

class LoginWidget extends StatefulWidget {
  final Color accentColor;

  const LoginWidget({super.key,
    required this.accentColor,
  });

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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
              style: TextStyle(fontSize: 15),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
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
                  fontSize: 12, // más pequeño
                  height: 0.8,  // ocupa menos espacio
                          ),
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
              style: TextStyle(fontSize: 15),
              textAlign: TextAlign.center,
              obscureText: true,
              decoration: InputDecoration(
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Process data.
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
    );
  }
}
