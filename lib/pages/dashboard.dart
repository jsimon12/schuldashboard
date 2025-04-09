import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'room_plan_screen.dart';
import 'temperature_card.dart';
import 'air_quality_card.dart';
import 'sensor_selection_section.dart';
import 'login.dart';

class DashboardScreen extends StatefulWidget {
  final String label;

  DashboardScreen({required this.label});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String weatherDescription = "Lade...";
  String temperature = "--";
  IconData weatherIcon = Icons.wb_cloudy;
  Timer? _weatherTimer;

  @override
  void initState() {
    super.initState();
    fetchWeather();

    // Starte Wiederholung alle 60 Minuten
    _weatherTimer = Timer.periodic(Duration(minutes: 15), (timer) {
      fetchWeather();
    });
  }

  @override
  void dispose() {
    _weatherTimer?.cancel(); // Wichtig: Timer stoppen bei Verlassen des Screens
    super.dispose();
  }

  Future<void> fetchWeather() async {
   final url = Uri.parse('https://wttr.in/Koblenz?format=j1&lang=de');
    final response = await http.get(
  url,
  headers: {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36',
  },
);

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final current = data["current_condition"][0];
        final temp = current["temp_C"];
        final desc = current["lang_de"][0]["value"];

        IconData icon = Icons.wb_cloudy;
        final descLower = desc.toLowerCase();

        if (descLower.contains("sun") || descLower.contains("clear")) {
          icon = Icons.wb_sunny;
        } else if (descLower.contains("cloud")) {
          icon = Icons.cloud;
        } else if (descLower.contains("rain")) {
          icon = Icons.grain;
        } else if (descLower.contains("snow")) {
          icon = Icons.ac_unit;
        } else if (descLower.contains("storm") || descLower.contains("thunder")) {
          icon = Icons.flash_on;
        }

        setState(() {
          weatherDescription = desc;
          temperature = "$temp°C";
          weatherIcon = icon;
        });
      } else {
        setState(() {
          weatherDescription = "Fehler";
          temperature = "--";
          weatherIcon = Icons.error;
        });
      }
    } catch (e) {
      setState(() {
        weatherDescription = "Offline";
        temperature = "--";
        weatherIcon = Icons.wifi_off;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2C0D52),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Dashboard",
            style: TextStyle(color: Colors.white, fontSize: 24)),
        actions: [
          IconButton(
            icon: Icon(Icons.map, color: Colors.white, size: 30),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RoomPlanScreen(label: widget.label),
                ),
              );
            },
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(weatherDescription,
                  style: TextStyle(color: Colors.white)),
              Text(temperature,
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          SizedBox(width: 10),
          Icon(weatherIcon, color: Colors.white, size: 30),
          SizedBox(width: 20),
          Icon(Icons.notifications, color: Colors.white),
          SizedBox(width: 10),
          PopupMenuButton<String>(
            icon: Icon(Icons.person, color: Colors.white),
            offset: Offset(0, 40),
            onSelected: (value) async {
              if (value == 'logout') {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
            color: Colors.white,
          ),
          SizedBox(width: 20),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: AirQualityCard()),
                  SizedBox(width: 16),
                  Expanded(child: TemperatureCard()),
                ],
              ),
            ),
          ),
          SensorSelectionSection(label: widget.label),
        ],
      ),
    );
  }
}
