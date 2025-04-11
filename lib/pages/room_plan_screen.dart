// Importiert notwendige Pakete
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:schuldashboard/l10n/app_localizations.dart';
import 'package:schuldashboard/pages/mqtt_service.dart';

/// Bildschirm, der aktuelle Sensorwerte in einem Raumplan-Layout darstellt
class RoomPlanScreen extends StatefulWidget {
  final String label; // z. B. Temperatur, Luftfeuchtigkeit
  final List<String>? filteredTopics; // Optional: zeigt nur bestimmte Topics

  RoomPlanScreen({required this.label, this.filteredTopics});

  @override
  _RoomPlanScreenState createState() => _RoomPlanScreenState();
}

class _RoomPlanScreenState extends State<RoomPlanScreen> {
  final Map<String, String> _latestMessages = {}; // Letzte Werte pro Topic
  final Map<String, DateTime> _messageTimestamps = {}; // Zeitstempel der letzten Werte

  // Filter für Gebäude, Etage, Raum
  String? _selectedBuilding;
  String? _selectedFloor;
  String? _selectedRoom;

  late final StreamSubscription<Map<String, String>> _mqttSubscription;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    // Lauscht auf neue MQTT-Nachrichten
    _mqttSubscription = MqttService().messageStream.listen((msg) {
      if (_isDisposed) return;
      final topic = msg['topic'];
      final payload = msg['payload'];

      // Nur einfache Werte (z. B. "23.5") verarbeiten – keine JSON-Objekte
      if (!_isComplexPayload(payload!)) {
        setState(() {
          _latestMessages[topic!] = payload;
          _messageTimestamps[topic] = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _mqttSubscription.cancel();
    super.dispose();
  }

  // Prüft, ob der Payload ein komplexes JSON-Objekt ist
  bool _isComplexPayload(String payload) {
    try {
      final decoded = json.decode(payload);
      return decoded is Map;
    } catch (_) {
      return false;
    }
  }

  // Ermittelt den passenden Sensortyp (Topic-Endung) basierend auf dem Label
  String? getSensorKeyword(String label) {
    switch (label.toLowerCase()) {
      case "licht":
      case "light":
        return "light";
      case "temperatur":
      case "temperature":
        return "temp";
      case "fenster":
      case "window":
      case "rollladen":
      case "shutter":
        return "roller_shutter";
      case "luftfeuchtigkeit":
      case "humidity":
      case "luftqualität":
        return "hum";
      default:
        return null;
    }
  }

  // Gibt das passende Icon für einen Sensor zurück
  Icon getSensorIcon(String label, String payload) {
    switch (getSensorKeyword(label)) {
      case "light":
        return Icon(Icons.lightbulb, color: Colors.yellow, size: 26);
      case "temp":
        return Icon(Icons.thermostat, color: Colors.redAccent, size: 26);
      case "roller_shutter":
        return Icon(
          payload == 'open' ? Icons.window : Icons.window_outlined,
          color: Colors.blue,
          size: 26,
        );
      case "hum":
        return Icon(Icons.water_drop, color: Colors.lightBlueAccent, size: 26);
      default:
        return Icon(Icons.device_unknown, color: Colors.grey, size: 26);
    }
  }

  // Gibt die Einheit für den Sensorwert zurück
  String getSensorUnit(String label) {
    switch (getSensorKeyword(label)) {
      case "light":
        return "Lux";
      case "temp":
        return "°C";
      case "roller_shutter":
        return "";
      case "hum":
        return "%";
      default:
        return "";
    }
  }

  // Lokalisierte Darstellung von Raum-, Etagen- und Gebäudebezeichnungen
  String convertRoomToString(String room) {
    final match = RegExp(r'room_0?(\d+)').firstMatch(room);
    return match != null ? '${AppLocalizations.of(context)!.room} ${match.group(1)}' : room;
  }

  String convertBuildingToString(String building) {
    final loc = AppLocalizations.of(context)!;
    switch (building) {
      case "building_a": return "${loc.building} A";
      case "building_b": return "${loc.building} B";
      case "building_c": return "${loc.building} C";
      default: return building;
    }
  }

  String convertFloorToString(String floor) {
    final match = RegExp(r'floor_?([a-zA-Z0-9]+)').firstMatch(floor);
    if (match != null) {
      final val = match.group(1);
      if (val == "e" || val == "E") return "${AppLocalizations.of(context)!.floor} E";
      return "${AppLocalizations.of(context)!.floor} $val";
    }
    return floor;
  }

  // Widget für eine einzelne Raumkarte
  Widget buildRoomCard(String topic, String payload) {
    final loc = AppLocalizations.of(context)!;
    final parts = topic.split('/');
    final building = parts[1];
    final floor = parts[2];
    final room = parts[3];

    final icon = getSensorIcon(widget.label, payload);
    final unit = getSensorUnit(widget.label);
    final isAlarm = MqttService().activeAlarms.containsKey(topic);

    List<String> lines = [];

    if (_selectedBuilding == null) lines.add(convertBuildingToString(building));
    if (_selectedBuilding == null || _selectedFloor == null) lines.add(convertFloorToString(floor));
    if (_selectedRoom == null) lines.add(convertRoomToString(room));

    lines.add("$payload $unit".trim());

    if (_messageTimestamps.containsKey(topic)) {
      final timeStr = TimeOfDay.fromDateTime(_messageTimestamps[topic]!).format(context);
      lines.add("${loc.updatedAt}: $timeStr");
    }

    return Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isAlarm ? Colors.red.shade300 : Colors.deepPurple.shade700,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAlarm ? Colors.red.shade900 : Colors.deepPurple.shade700,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                line,
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Filtert alle empfangenen Nachrichten nach ausgewähltem Sensor und Raum
  List<Map<String, String>> get _filteredMessages {
    final keyword = getSensorKeyword(widget.label);

    List<Map<String, String>> result = _latestMessages.entries
        .where((entry) {
          final topic = entry.key;
          final parts = topic.split('/');
          if (parts.length < 5) return false;

          final building = parts[1];
          final floor = parts[2];
          final room = parts[3];
          final type = parts[4];

          final matchesFilter = (_selectedBuilding == null || building == _selectedBuilding) &&
                                (_selectedFloor == null || floor == _selectedFloor) &&
                                (_selectedRoom == null || room == _selectedRoom) &&
                                (keyword == null || type.contains(keyword));

          final isInCriticalList = widget.filteredTopics == null || widget.filteredTopics!.contains(topic);
          return matchesFilter && isInCriticalList;
        })
        .map((entry) => {'topic': entry.key, 'payload': entry.value})
        .toList();

    // Sortiert nach Gebäude, Etage, Raum
    result.sort((a, b) {
      final aParts = a['topic']!.split('/');
      final bParts = b['topic']!.split('/');

      final buildingOrder = {'building_a': 0, 'building_b': 1, 'building_c': 2};
      final floorOrder = {'floor_u': 0, 'floor_e': 1, 'floor_1': 2, 'floor_2': 3, 'floor_3': 4, 'floor_4': 5, 'floor_5': 6};

      int compareBuilding = (buildingOrder[aParts[1]] ?? 99).compareTo(buildingOrder[bParts[1]] ?? 99);
      if (compareBuilding != 0) return compareBuilding;

      int compareFloor = (floorOrder[aParts[2]] ?? 99).compareTo(floorOrder[bParts[2]] ?? 99);
      if (compareFloor != 0) return compareFloor;

      int aRoom = int.tryParse(RegExp(r'room_0?(\d+)').firstMatch(aParts[3])?.group(1) ?? '') ?? 999;
      int bRoom = int.tryParse(RegExp(r'room_0?(\d+)').firstMatch(bParts[3])?.group(1) ?? '') ?? 999;
      return aRoom.compareTo(bRoom);
    });

    return result;
  }

  List<String> get _availableBuildings => ["building_a", "building_b", "building_c"];
  List<String> get _availableFloors => ["floor_1", "floor_2", "floor_3", "floor_5", "floor_e"];

  // Liefert alle verfügbaren Räume, basierend auf der Filterung
  List<String> get _availableRooms {
    return _latestMessages.keys
        .where((topic) =>
            (_selectedBuilding == null || topic.contains(_selectedBuilding!)) &&
            (_selectedFloor == null || topic.contains(_selectedFloor!)))
        .map((topic) => topic.split('/')[3])
        .toSet()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Color(0xFF2C0D52),
      appBar: AppBar(
        leading: BackButton(color: Colors.white),
        title: Text(
          "${widget.label} ${loc.roomPlan}",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDropdown(loc.selectBuilding, _selectedBuilding, _availableBuildings, convertBuildingToString, (val) {
                  setState(() {
                    _selectedBuilding = val;
                    _selectedFloor = null;
                    _selectedRoom = null;
                  });
                }),
                _buildDropdown(loc.selectFloor, _selectedFloor, _availableFloors, convertFloorToString, (val) {
                  setState(() {
                    _selectedFloor = val;
                    _selectedRoom = null;
                  });
                }),
                _buildDropdown(loc.selectRoom, _selectedRoom, _availableRooms, convertRoomToString, (val) {
                  setState(() => _selectedRoom = val);
                }),
              ],
            ),
          ),
        ),
      ),
      body: _filteredMessages.isEmpty
          ? Center(
              child: Text(
                loc.noData,
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            )
          : GridView.count(
              crossAxisCount: 5,
              padding: EdgeInsets.all(6),
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              children: _filteredMessages.map((msg) {
                return buildRoomCard(msg['topic']!, msg['payload']!);
              }).toList(),
            ),
    );
  }

  // Baut ein Dropdown-Menü
  Widget _buildDropdown(
    String hint,
    String? value,
    List<String> items,
    String Function(String) displayFn,
    void Function(String?) onChanged,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade400,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        value: value,
        dropdownColor: Colors.deepPurple.shade300,
        hint: Text(hint, style: TextStyle(color: Colors.white, fontSize: 16)),
        icon: Icon(Icons.arrow_drop_down, color: Colors.white),
        underline: SizedBox(),
        style: TextStyle(color: Colors.white, fontSize: 16),
        items: items
            .map((val) => DropdownMenuItem(
                  value: val,
                  child: Text(displayFn(val), style: TextStyle(fontSize: 16)),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
