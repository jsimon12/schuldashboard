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
      // Versuche, den Benutzer mit Firebase Auth zu authentifizieren
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      
      // Erfolgreicher Login: Weiterleitung zum Home-Screen oder Dashboard
      if (userCredential.user != null) {
        print("Login erfolgreich!");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen(label: "Dashboard")),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Fehler beim Login: ${e.message}';
      // Zeige Fehlernachricht an
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
      backgroundColor: Color(0xFF2C0D52), // Hintergrundfarbe der Seite
      appBar: AppBar(
        title: Text('CBS Dashboard'),
        centerTitle: true,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 34),
        backgroundColor: Color(0xFF2C0D52), // AppBar-Farbe
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            width: 350, // Container-Breite explizit festgelegt
            padding: EdgeInsets.all(20), // Innenabstand des Containers
            decoration: BoxDecoration(
              color: Colors.white, // Hintergrundfarbe des Containers
              borderRadius: BorderRadius.circular(12), // Abgerundete Ecken
              boxShadow: [
                BoxShadow(
                  color: Colors.black26, // Schattenfarbe
                  offset: Offset(0, 4), // Position des Schattens
                  blurRadius: 6, // Weichzeichnung des Schattens
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Container passt sich an den Inhalt an
              children: <Widget>[
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'E-Mail',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Passwort',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(), // Hier wird bei Enter gedrückt!
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _login,
                  child: Text('Login'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 40),
                    backgroundColor: Color(0xFF2C0D52), // Button-Farbe
                    textStyle: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
