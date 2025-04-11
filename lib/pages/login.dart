// Notwendige Imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:schuldashboard/pages/dashboard.dart';

// Stateful Widget, um Login mit interaktivem Zustand (z. B. Eingabefelder) zu verwalten
class LoginScreen extends StatefulWidget {
  final VoidCallback? toggleLocale; // Funktion zum Umschalten der Sprache (optional)

  const LoginScreen({super.key, this.toggleLocale});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller für E-Mail- und Passwort-Felder
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Firebase Authentication Instanz
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Login-Funktion mit Firebase
  Future<void> _login() async {
    try {
      // Führt den Login mit E-Mail und Passwort aus
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Wenn erfolgreich, weiter zur Dashboard-Seite navigieren
      if (userCredential.user != null) {
        print("Login erfolgreich!");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(
              label: "Dashboard",
              toggleLocale: widget.toggleLocale, // Sprachumschalter wird weitergegeben
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Fehlerbehandlung: Zeigt einen AlertDialog mit Fehlermeldung
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
                  Navigator.of(context).pop(); // Dialog schließen
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  // UI wird hier aufgebaut
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2C0D52), // Hintergrundfarbe lila
      appBar: AppBar(
        title: Text('CBS Dashboard'),
        centerTitle: true,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 34),
        backgroundColor: Color(0xFF2C0D52),
        actions: [
          // Sprachumschalter oben rechts
          IconButton(
            icon: Icon(Icons.language, color: Colors.white),
            tooltip: 'Sprache wechseln',
            onPressed: widget.toggleLocale,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Theme(
            // Lokales Theme für weiße Eingabemaske
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
                color: Colors.white, // Karte in weißer Farbe
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
                mainAxisSize: MainAxisSize.min, // Nur so hoch wie nötig
                children: <Widget>[
                  // Eingabefeld für E-Mail
                  TextField(
                    controller: _emailController,
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'E-Mail',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Eingabefeld für Passwort
                  TextField(
                    controller: _passwordController,
                    obscureText: true, // Versteckt Passwort
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Passwort',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(), // Login bei Enter
                  ),
                  SizedBox(height: 20),

                  // Login-Button
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
