import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:schuldashboard/pages/dashboard.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Login-Funktion
  Future<void> _login() async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (userCredential.user != null) {
        print("Login erfolgreich!");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen(label: "Dashboard")),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Fehler beim Login: ${e.message}';
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Login fehlgeschlagen'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2C0D52),
      appBar: AppBar(
        title: Text('CBS Dashboard'),
        centerTitle: true,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 34),
        backgroundColor: Color(0xFF2C0D52),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Theme(
            data: ThemeData(
              textTheme: TextTheme(
                bodyMedium: TextStyle(color: Colors.black),
              ),
              inputDecorationTheme: InputDecorationTheme(
                labelStyle: TextStyle(color: Colors.black87),
              ),
            ),
            child: Container(
              width: 350,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 4),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: _emailController,
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'E-Mail',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Passwort',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _login,
                    child: Text('Login'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 40),
                      backgroundColor: Color(0xFF2C0D52),
                      textStyle: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
