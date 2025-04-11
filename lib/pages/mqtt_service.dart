// Importiert die benötigten Pakete
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Singleton-Service zur Verarbeitung von MQTT-Nachrichten
class MqttService {
  late MqttServerClient _client;

  // Singleton-Pattern (eine Instanz für die ganze App)
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;
  MqttService._internal();

  // Streams für Live-Daten, Alarme und Temperaturverlauf
  final StreamController<Map<String, String>> _messageStreamController = StreamController.broadcast();
  final StreamController<List<AlarmEntry>> _alarmStreamController = StreamController.broadcast();
  final StreamController<void> _historyStreamController = StreamController.broadcast();

  // Letzte empfangene Werte pro Topic
  Map<String, String> latestMessages = {};
  Map<String, DateTime> messageTimestamps = {};

  // Aktive Alarme (nach Topic)
  Map<String, AlarmEntry> activeAlarms = {};

  // Verlauf der Temperaturwerte
  List<TemperatureEntry> _temperatureHistory = [];
  final Map<String, DateTime> _lastSavedTimestamps = {};

  // Getter für Streams und History
  Stream<Map<String, String>> get messageStream => _messageStreamController.stream;
  Stream<List<AlarmEntry>> get alarmStream => _alarmStreamController.stream;
  Stream<void> get historyStream => _historyStreamController.stream;
  List<TemperatureEntry> get temperatureHistory => _temperatureHistory;

  /// Stellt eine Verbindung zum MQTT-Broker her
  Future<void> connect() async {
    _client = MqttServerClient(
      'test.mosquitto.org',
      'flutter_client_${DateTime.now().millisecondsSinceEpoch}', // eindeutiger Clientname
    );
    _client.port = 1883;
    _client.keepAlivePeriod = 20;
    _client.logging(on: false); // Logging deaktivieren
    _client.onDisconnected = () {};
    _client.onConnected = () {};
    _client.onSubscribed = (topic) {};

    final connMess = MqttConnectMessage()
        .withClientIdentifier('flutter_client_${DateTime.now().millisecondsSinceEpoch}')
        .startClean()
        .keepAliveFor(20)
        .withWillQos(MqttQos.atMostOnce);

    _client.connectionMessage = connMess;

    try {
      final result = await _client.connect();
      if (result?.state == MqttConnectionState.connected) {
        _subscribeTopics();
      }
    } catch (_) {
      // Fehler beim Verbinden ignorieren (könnte geloggt werden)
    }
  }

  /// Abonniert das Topic 'cbssimulation/#'
  void _subscribeTopics() {
    const topic = 'cbssimulation/#';
    _client.subscribe(topic, MqttQos.atMostOnce);

    // Listener für neue Nachrichten
    _client.updates!.listen((c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final topic = c[0].topic;

      handleIncoming(topic, payload);
    });
  }

  /// Behandelt eingehende MQTT-Nachrichten
  void handleIncoming(String topic, String payload) {
    latestMessages[topic] = payload;
    messageTimestamps[topic] = DateTime.now();
    _messageStreamController.add({'topic': topic, 'payload': payload});
    _checkForAlarms(topic, payload);

    // Temperaturverlauf speichern
    if (topic.contains("temp")) {
      _temperatureHistory.add(
        TemperatureEntry(topic: topic, payload: payload, timestamp: DateTime.now()),
      );
      if (_temperatureHistory.length > 1000) _temperatureHistory.removeAt(0);
      _historyStreamController.add(null);
    }

    // Speicherung in Firestore (alle 2 Minuten pro Topic)
    final now = DateTime.now();
    final lastSaved = _lastSavedTimestamps[topic];
    if (lastSaved != null && now.difference(lastSaved) < Duration(minutes: 2)) return;
    _lastSavedTimestamps[topic] = now;

    final parts = topic.split('/');
    if (parts.length >= 3) {
      final building = parts[1];
      final floor = parts[2];
      final room = parts.length > 3 ? parts[3] : "unknown";

      FirebaseFirestore.instance.collection('sensor_data').add({
        'building': building,
        'floor': floor,
        'room': room,
        'topic': topic,
        'payload': payload,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Prüft, ob der empfangene Wert außerhalb definierter Schwellen liegt (→ Alarm)
  void _checkForAlarms(String topic, String payload) {
    if (topic.contains("temp")) {
      double? value = double.tryParse(payload);
      if (value != null && (value > 28 || value < 10)) {
        _addAlarm(topic, sensorLabel: "temp", value: value.toStringAsFixed(1));
      } else {
        _removeAlarm(topic);
      }
    } else if (topic.contains("hum")) {
      double? value = double.tryParse(payload);
      if (value != null && (value > 75 || value < 40)) {
        _addAlarm(topic, sensorLabel: "hum", value: value.toStringAsFixed(1));
      } else {
        _removeAlarm(topic);
      }
    }
  }

  /// Fügt einen neuen Alarm hinzu (z. B. zu hohe Temperatur)
  void _addAlarm(String topic, {required String sensorLabel, required String value}) {
    activeAlarms[topic] = AlarmEntry(
      topic: topic,
      sensorLabel: sensorLabel,
      value: value,
    );
    _alarmStreamController.add(activeAlarms.values.toList());
  }

  /// Entfernt einen Alarm, wenn Werte wieder im Normalbereich sind
  void _removeAlarm(String topic) {
    if (activeAlarms.remove(topic) != null) {
      _alarmStreamController.add(activeAlarms.values.toList());
    }
  }
}

/// Modell für einen Alarm-Eintrag
class AlarmEntry {
  final String topic;
  final String sensorLabel;
  final String value;

  AlarmEntry({
    required this.topic,
    required this.sensorLabel,
    required this.value,
  });

  // Optional: eigene Nachricht, aktuell nicht genutzt
  String? get message => null;
}

/// Modell für einen Temperatur-Eintrag (für History)
class TemperatureEntry {
  final String topic;
  final String payload;
  final DateTime timestamp;

  TemperatureEntry({
    required this.topic,
    required this.payload,
    required this.timestamp,
  });
}
