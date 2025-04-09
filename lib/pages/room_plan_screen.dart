import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomPlanScreen extends StatefulWidget {
  final String label;

  RoomPlanScreen({required this.label});

  @override
  _RoomPlanScreenState createState() => _RoomPlanScreenState();
}

class _RoomPlanScreenState extends State<RoomPlanScreen> {
  late MqttServerClient _mqttClient;
  final List<Map<String, String>> _messages = [];
  String? _selectedBuilding;
  String? _selectedFloor;
  String? _selectedRoom;
  String? _livePayload; // Variable für den letzten Payload

  @override
  void initState() {
    super.initState();
    _setupMqttClient();
    print("📍 initState aufgerufen");
  }

  void _setupMqttClient() async {
    _mqttClient = MqttServerClient.withPort(
        'test.mosquitto.org',
        'flutter_${DateTime.now().millisecondsSinceEpoch}',
        1883);
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
          _messages.insert(0, {"topic": topic, "payload": payload});
          _livePayload = payload; // Speichert den letzten Payload-Wert
        });

        _saveMessageToFirebase(topic, payload);
      });
    }
  }

  void _onDisconnected() => print('🔌 Verbindung getrennt');
  void _onConnected() => print('🔗 Verbunden');
  void _onSubscribed(String topic) => print('📌 Abonniert: $topic');

  void _saveMessageToFirebase(String topic, String message) {
    List<String> topicParts = topic.split('/');
    CollectionReference ref = FirebaseFirestore.instance.collection('mqtt-data');

    for (var part in topicParts) {
      ref = ref.doc(part).collection(part);
    }

    ref.add({
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    }).then((_) {
      print('✅ Nachricht erfolgreich gespeichert: $topic');
    }).catchError((error) {
      print('❌ Fehler beim Speichern: $error');
    });
  }

  String? formatBuilding(String? value) {
    switch (value) {
      case "Gebäude A":
        return "building_a";
      case "Gebäude B":
        return "building_b";
      case "Gebäude C":
        return "building_c";
      default:
        return null;
    }
  }

  String? formatFloor(String? value) {
    switch (value) {
      case "Etage 1":
        return "floor_1";
      case "Etage 2":
        return "floor_2";
      case "Etage 3":
        return "floor_3";
      case "Etage E":
        return "floor_e";
      default:
        return null;
    }
  }

  String? getSensorTopicKeyword(String label) {
    switch (label.toLowerCase()) {
      case "licht":
        return "light";
      case "temperatur":
        return "temp";
      case "fenster":
        return "roller_shutter";
      case "luftqualität":
        return "hum";
      default:
        return null;
    }
  }

  Icon _getIconForTopic(String topic, String payload) {
    String sensor = getSensorTopicKeyword(widget.label) ?? '';

    if (sensor == 'light') {
      return Icon(
        payload == '1' ? Icons.lightbulb : Icons.lightbulb_outline,
        color: payload == '1' ? Colors.yellow : Colors.grey,
      );
    } else if (sensor == 'temp') {
      double temp = double.tryParse(payload) ?? 0;
      return Icon(
        temp > 25 ? Icons.thermostat_outlined : Icons.thermostat_rounded,
        color: temp > 25 ? Colors.red : Colors.blue,
      );
    } else if (sensor == 'roller_shutter') {
      return Icon(
        payload == 'open' ? Icons.open_in_new : Icons.close,
        color: payload == 'open' ? Colors.blue : Colors.grey,
      );
    } else if (sensor == 'hum') {
      int humidity = int.tryParse(payload) ?? 0;
      return Icon(
        humidity > 60 ? Icons.air_outlined : Icons.air_rounded,
        color: humidity > 60 ? Colors.green : Colors.blue,
      );
    }

    return Icon(Icons.help_outline); // Standard-Icon für unbekannte Sensoren
  }

  List<Map<String, String>> get _filteredMessages {
    final selectedBuilding = formatBuilding(_selectedBuilding);
    final selectedFloor = formatFloor(_selectedFloor);
    final selectedRoom = _selectedRoom;
    final sensorKeyword = getSensorTopicKeyword(widget.label);

    return _messages.where((msg) {
      final topic = msg["topic"]!;
      final matchesBuilding = selectedBuilding == null || topic.contains(selectedBuilding);
      final matchesFloor = selectedFloor == null || topic.contains(selectedFloor);
      final matchesRoom = selectedRoom == null || topic.contains(selectedRoom!);
      final matchesSensor = sensorKeyword == null || topic.contains(sensorKeyword);
      return matchesBuilding && matchesFloor && matchesRoom && matchesSensor;
    }).toList();
  }

  List<String> get _filteredRooms {
    final selectedBuilding = formatBuilding(_selectedBuilding);
    final selectedFloor = formatFloor(_selectedFloor);

    final rooms = _messages
        .map((msg) => msg["topic"]!)
        .where((topic) =>
            (selectedBuilding == null || topic.contains(selectedBuilding)) &&
            (selectedFloor == null || topic.contains(selectedFloor)))
        .map((topic) {
          final parts = topic.split('/');
          return parts.length >= 4 ? parts[3] : '';
        })
        .toSet()
        .where((room) => room.isNotEmpty)
        .toList()
      ..sort();

    return rooms;
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
          // Bereich für den Live-Wert oben
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _livePayload != null ? "Live Wert: $_livePayload" : "Keine Daten verfügbar",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              DropdownButton<String>(
                value: _selectedBuilding,
                items: ["Gebäude A", "Gebäude B", "Gebäude C"]
                    .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBuilding = value;
                    _selectedRoom = null;
                  });
                },
                hint: Text("Gebäude wählen"),
              ),
              DropdownButton<String>(
                value: _selectedFloor,
                items: ["Etage 1", "Etage 2", "Etage 3", "Etage E"]
                    .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFloor = value;
                    _selectedRoom = null;
                  });
                },
                hint: Text("Etage wählen"),
              ),
              DropdownButton<String>(
                value: _selectedRoom,
                items: _filteredRooms
                    .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                    .toList(),
                onChanged: _filteredRooms.isNotEmpty
                    ? (value) {
                        setState(() {
                          _selectedRoom = value;
                        });
                      }
                    : null,
                hint: Text("Raum wählen"),
              ),
            ],
          ),
          Expanded(
            child: _filteredMessages.isEmpty
                ? Center(child: Text("Keine passenden Nachrichten gefunden"))
                : ListView.builder(
                    itemCount: _filteredMessages.length,
                    itemBuilder: (context, index) {
                      final msg = _filteredMessages[index];
                      return ListTile(
                        leading: _getIconForTopic(msg["topic"]!, msg["payload"]!),
                        title: Text(msg["payload"]!), // Nur den Payload anzeigen
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
