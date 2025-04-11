import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:schuldashboard/firebase_options.dart';
import 'package:schuldashboard/pages/mqtt_service.dart';
import 'package:schuldashboard/pages/login.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await MqttService().connect(); // MQTT-Verbindung herstellen
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Schuldashboard',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.deepPurple,
          accentColor: Colors.deepPurpleAccent,
        ),
        dialogBackgroundColor: Colors.deepPurple.shade400,
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
          labelLarge: TextStyle(color: Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('de', 'DE'), // Deutsch
      ],
      home: LoginScreen(),
    );
  }
}
