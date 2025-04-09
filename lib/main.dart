import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:schuldashboard/firebase_options.dart';
import 'package:schuldashboard/pages/login.dart'; // Import der ShoppingListScreen aus start.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter Binding initialisieren
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CBS-Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home:LoginScreen(), // Setzen der Startseite auf die Dashboard-Seite
    );
  }
}
