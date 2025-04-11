// Flutter & Firebase & Lokalisierung
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';

// Projektinterne Importe
import 'firebase_options.dart'; // Firebase-Konfigurationsdaten
import 'pages/login.dart'; // Erste Seite: LoginScreen
import 'pages/mqtt_service.dart'; // MQTT-Service
import 'l10n/app_localizations.dart'; // Lokalisierung

/// Einstiegspunkt der App
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Wichtige Initialisierung vor Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Initialisierung mit Plattformdaten
  );
  await MqttService().connect(); // Verbindung zum MQTT-Broker herstellen
  runApp(MyApp()); // App starten
}

/// Root-Widget mit Zustandsverwaltung (für Sprachumschaltung)
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('de'); // Standard: Deutsch

  /// Funktion zur Sprachumschaltung zwischen Deutsch und Englisch
  void _toggleLocale() {
    setState(() {
      _locale = _locale.languageCode == 'de' ? const Locale('en') : const Locale('de');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Schuldashboard',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple, // Grundfarbe
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.deepPurple,
          accentColor: Colors.deepPurpleAccent,
        ),
        dialogBackgroundColor: Colors.deepPurple.shade400,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
          labelLarge: TextStyle(color: Colors.white),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.white70),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white54),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: Colors.deepPurple.shade300,
          headerBackgroundColor: Colors.deepPurple.shade600,
          headerForegroundColor: Colors.white,
          dayForegroundColor: MaterialStateProperty.all(Colors.white),
          todayBackgroundColor: MaterialStateProperty.all(Colors.white24),
          yearBackgroundColor: MaterialStateProperty.all(Colors.deepPurple.shade600),
        ),
      ),
      locale: _locale, // Aktuell gewählte Sprache
      localizationsDelegates: const [
        AppLocalizations.delegate, // Eigene Lokalisierung
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('de'), // Deutsch
        Locale('en'), // Englisch
      ],
      home: LoginScreen(toggleLocale: _toggleLocale), // Startbildschirm mit Sprachumschalter
    );
  }
}
