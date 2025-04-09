import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // Importiere Firebase Firestore

class RoomPlanScreen extends StatefulWidget {
  final String label;

  RoomPlanScreen({required this.label});

  @override
  _RoomPlanScreenState createState() => _RoomPlanScreenState();
}

class _RoomPlanScreenState extends State<RoomPlanScreen> {
  late MqttServerClient _mqttClient;
  String _lastMessage = '';
  String? _selectedBuilding;
  String? _selectedFloor;

  @override
  void initState() {
    super.initState();
    _setupMqttClient();
    print("📍 initState aufgerufen");
  }

  void _setupMqttClient() async {
    _mqttClient = MqttServerClient.withPort('test.mosquitto.org', 'flutter_${DateTime.now().millisecondsSinceEpoch}', 1883);
    _mqttClient.logging(on: true);  // Aktiviert das interne Logging
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
      print('✅ Verbunden mit MQTT-Broker');

      _mqttClient.subscribe('cbssimulation/#', MqttQos.atMostOnce);

      _mqttClient.updates?.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
        final MqttPublishMessage recMess = c![0].payload as MqttPublishMessage;
        final String payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        final String topic = c[0].topic;

        print('📩 Nachricht empfangen: $topic → $payload');

        setState(() {
          _lastMessage = 'Topic: $topic\nPayload: $payload';
        });

        // Speichere die Nachricht in Firebase
        _saveMessageToFirebase(topic, payload);
      });
    } else {
      print('❌ Verbindung fehlgeschlagen: ${_mqttClient.connectionStatus}');
    }
  }

  void _onDisconnected() {
    print('🔌 Verbindung getrennt');
  }

  void _onConnected() {
    print('🔗 Verbunden');
  }

  void _onSubscribed(String topic) {
    print('📌 Abonniert: $topic');
  }

  void _saveMessageToFirebase(String topic, String message) {
    // Extrahiere Teile des Topics (z.B. cbssimulation/buildingA/floor1/room1)
    List<String> topicParts = topic.split('/');

    // Beginne mit der Referenz zur Firestore-Sammlung
    CollectionReference ref = FirebaseFirestore.instance.collection('mqtt-data');

    // Iteriere durch die Teile des Topics und baue die Struktur auf
    for (var part in topicParts) {
      ref = ref.doc(part).collection(part); // Jede Ebene wird zur Sammlung der nächsten Ebene
    }

    // Speichere die Nachricht in der letzten Sammlung (basierend auf dem letzten Teil des Topics)
    ref.add({
      'message': message,
      'timestamp': FieldValue.serverTimestamp(), // Optionaler Zeitstempel
    }).then((_) {
      print('✅ Nachricht erfolgreich in Firestore gespeichert unter Topic $topic');
    }).catchError((error) {
      print('❌ Fehler beim Speichern der Nachricht in Firestore: $error');
    });
  }

  @override
  void dispose() {
    _mqttClient.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.label} Raumplan")),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              DropdownButton<String>(
                value: _selectedBuilding,
                items: ["Gebäude A", "Gebäude B", "Gebäude C"].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBuilding = value;
                  });
                },
                hint: Text("Gebäude wählen"),
              ),
              DropdownButton<String>(
                value: _selectedFloor,
                items: ["Etage 1", "Etage 2", "Etage 3"].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFloor = value;
                  });
                },
                hint: Text("Etage wählen"),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Hier wird der Raumplan angezeigt", style: TextStyle(fontSize: 18)),
                  SizedBox(height: 20),
                  Text("Empfangene MQTT-Nachricht:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      _lastMessage,
                      style: TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
