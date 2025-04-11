import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  late MqttServerClient _mqttClient;
  String weatherDescription = "Lade...";
  String temperature = "--";
  IconData weatherIcon = Icons.wb_cloudy;
  Timer? _weatherTimer;

  // MQTT Daten
  List<Map<String, String>> _mqttMessages = [];

  @override
  void initState() {
    super.initState();
    fetchWeather();
    _setupMqttClient();

    // Starte Wiederholung alle 60 Minuten
    _weatherTimer = Timer.periodic(Duration(minutes: 15), (timer) {
      fetchWeather();
    });
  }

  @override
  void dispose() {
    _weatherTimer?.cancel(); // Wichtig: Timer stoppen bei Verlassen des Screens
    _mqttClient.disconnect(); // MQTT Verbindung trennen
    super.dispose();
  }

  Future<void> fetchWeather() async {
    final url = Uri.parse('https://wttr.in/Koblenz?format=j1&lang=de');
    final response = await http.get(url, headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36',
    });

    try {
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

  void _setupMqttClient() async {
    _mqttClient = MqttServerClient.withPort(
      'test.mosquitto.org',
      'flutter_${DateTime.now().millisecondsSinceEpoch}',
      1883,
    );

    _mqttClient.logging(on: true);
    _mqttClient.keepAlivePeriod = 20;
    _mqttClient.onDisconnected = _onDisconnected;
    _mqttClient.onConnected = _onConnected;
    _mqttClient.onSubscribed = _onSubscribed;

    final connMess = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    _mqttClient.connectionMessage = connMess;

    try {
      await _mqttClient.connect();
      if (_mqttClient.connectionStatus?.state == MqttConnectionState.connected) {
        print('✅ Verbunden mit MQTT-Broker');
        _mqttClient.subscribe('cbssimulation/#', MqttQos.atMostOnce);
      } else {
        print('❌ Fehler bei der Verbindung: ${_mqttClient.connectionStatus?.state}');
      }
    } catch (e) {
      print('❌ Fehler beim Verbinden: $e');
      _mqttClient.disconnect();
    }

    if (_mqttClient.connectionStatus?.state == MqttConnectionState.connected) {
      _mqttClient.updates?.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
        final MqttPublishMessage recMess = c![0].payload as MqttPublishMessage;
        final String payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        final String topic = c[0].topic;

        print('📩 Nachricht empfangen: $topic → $payload');

        setState(() {
          _mqttMessages.insert(0, {"topic": topic, "payload": payload});
        });
      });
    }
  }

  void _onDisconnected() => print('🔌 Verbindung getrennt');
  void _onConnected() => print('🔗 Verbunden');
  void _onSubscribed(String topic) => print('📌 Abonniert: $topic');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2C0D52),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Dashboard", style: TextStyle(color: Colors.white, fontSize: 24)),
        actions: [
          IconButton(
            icon: Icon(Icons.map, color: Colors.white, size: 30),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RoomPlanScreen(
                    label: widget.label,
                    mqttMessages: _mqttMessages, // MQTT-Daten übergeben
                  ),
                ),
              );
            },
          ),
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
              PopupMenuItem<String>(value: 'logout', child: Text('Logout')),
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
