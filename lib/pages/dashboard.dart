import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:schuldashboard/pages/mqtt_service.dart';
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
  List<AlarmEntry> _alarms = [];

  String weatherDescription = "Lade...";
  String temperature = "--";
  IconData weatherIcon = Icons.wb_cloudy;
  Timer? _weatherTimer;

  @override
  void initState() {
    super.initState();

    MqttService().alarmStream.listen((alarms) {
      if (mounted) {
        setState(() {
          _alarms = alarms;
        });
      }
    });

    fetchWeather();

    _weatherTimer = Timer.periodic(Duration(minutes: 15), (timer) {
      fetchWeather();
    });
  }

  @override
  void dispose() {
    _weatherTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchWeather() async {
    final url = Uri.parse('https://wttr.in/Koblenz?format=j1&lang=de');
    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36',
        },
      );

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

  void _showAlarmDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            minWidth: 300,
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Aktuelle Warnungen",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              SizedBox(height: 12),
              Expanded(
                child: _alarms.isEmpty
                    ? Center(
                        child: Text(
                          "Keine kritischen Werte.",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _alarms.length,
                        separatorBuilder: (_, __) => SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final alarm = _alarms[index];

                          // Alle kritischen Topics mit gleichem sensorLabel (z.B. temp)
                          final matchingTopics = _alarms
                              .where((a) => a.sensorLabel == alarm.sensorLabel)
                              .map((a) => a.topic)
                              .toList();

                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RoomPlanScreen(
                                    label: alarm.sensorLabel,
                                    filteredTopics: matchingTopics,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.deepPurple.shade200),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          alarm.title,
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.deepPurple),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          alarm.message,
                                          style: TextStyle(fontSize: 14, color: Colors.black54),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          "Topic: ${alarm.topic}",
                                          style: TextStyle(fontSize: 12, color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Schließen", style: TextStyle(color: Colors.deepPurple, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2C0D52),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Dashboard", style: TextStyle(color: Colors.white, fontSize: 24)),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(weatherDescription, style: TextStyle(color: Colors.white)),
              Text(temperature, style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          SizedBox(width: 10),
          Icon(weatherIcon, color: Colors.white, size: 30),
          SizedBox(width: 20),
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications, color: Colors.white),
                onPressed: _showAlarmDialog,
              ),
              if (_alarms.isNotEmpty)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(minWidth: 12, minHeight: 12),
                  ),
                ),
            ],
          ),
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
