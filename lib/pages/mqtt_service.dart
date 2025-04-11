import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class MqttService {
  late MqttServerClient _client;

  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;
  MqttService._internal();

  final StreamController<Map<String, String>> _messageStreamController = StreamController.broadcast();
  final StreamController<List<AlarmEntry>> _alarmStreamController = StreamController.broadcast();
  final StreamController<void> _historyStreamController = StreamController.broadcast();

  Map<String, String> latestMessages = {};
  Map<String, DateTime> messageTimestamps = {};
  Map<String, AlarmEntry> activeAlarms = {};

  List<TemperatureEntry> _temperatureHistory = [];

  Stream<Map<String, String>> get messageStream => _messageStreamController.stream;
  Stream<List<AlarmEntry>> get alarmStream => _alarmStreamController.stream;
  Stream<void> get historyStream => _historyStreamController.stream;
  List<TemperatureEntry> get temperatureHistory => _temperatureHistory;

  Future<void> connect() async {
    _client = MqttServerClient(
      'test.mosquitto.org',
      'flutter_client_${DateTime.now().millisecondsSinceEpoch}',
    );
    _client.port = 1883;
    _client.keepAlivePeriod = 20;
    _client.logging(on: false);

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
      // Fehlerbehandlung kann ergänzt werden
    }
  }

  void _subscribeTopics() {
    const topic = 'cbssimulation/#';
    _client.subscribe(topic, MqttQos.atMostOnce);

    _client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final topic = c[0].topic;
      handleIncoming(topic, payload);
    });
  }

  void handleIncoming(String topic, String payload) {
    latestMessages[topic] = payload;
    messageTimestamps[topic] = DateTime.now();
    _messageStreamController.add({'topic': topic, 'payload': payload});
    _checkForAlarms(topic, payload);

    // Temperaturverlauf lokal speichern
    if (topic.contains("temp")) {
      _temperatureHistory.add(
        TemperatureEntry(
          topic: topic,
          payload: payload,
          timestamp: DateTime.now(),
        ),
      );

      if (_temperatureHistory.length > 1000) {
        _temperatureHistory.removeAt(0); // Verlauf begrenzen
      }

      _historyStreamController.add(null);
    }

    // Save data to Firestore
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

  void _checkForAlarms(String topic, String payload) {
    if (topic.contains("temp")) {
      double? value = double.tryParse(payload);
      if (value != null && (value > 28 || value < 10)) {
        _addAlarm(topic, "Temperatur kritisch", "Wert: ${value.toStringAsFixed(1)} °C");
      } else {
        _removeAlarm(topic);
      }
    } else if (topic.contains("hum")) {
      double? value = double.tryParse(payload);
      if (value != null && (value > 75 || value < 40)) {
        _addAlarm(topic, "Luftfeuchtigkeit kritisch", "Wert: ${value.toStringAsFixed(1)}%");
      } else {
        _removeAlarm(topic);
      }
    }
  }

  void _addAlarm(String topic, String title, String message) {
    String sensorLabel = topic.contains("hum")
        ? "Luftfeuchtigkeit"
        : topic.contains("temp")
            ? "Temperatur"
            : "Unbekannt";

    activeAlarms[topic] = AlarmEntry(
      topic: topic,
      title: title,
      message: message,
      sensorLabel: sensorLabel,
    );

    _alarmStreamController.add(activeAlarms.values.toList());
  }

  void _removeAlarm(String topic) {
    if (activeAlarms.remove(topic) != null) {
      _alarmStreamController.add(activeAlarms.values.toList());
    }
  }
}

class AlarmEntry {
  final String topic;
  final String title;
  final String message;
  final String sensorLabel;

  AlarmEntry({
    required this.topic,
    required this.title,
    required this.message,
    required this.sensorLabel,
  });
}

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
