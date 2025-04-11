// Importieren von Bibliotheken für Netzwerk, Authentifizierung, Lokalisierung etc.
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:schuldashboard/l10n/app_localizations.dart';
import 'package:schuldashboard/pages/mqtt_service.dart';
import 'room_plan_screen.dart';
import 'temperature_card.dart';
import 'air_quality_card.dart';
import 'sensor_selection_section.dart';
import 'login.dart';

// Hauptbildschirm des Dashboards
class DashboardScreen extends StatefulWidget {
  final String label;
  final VoidCallback? toggleLocale; // Callback zum Sprachwechsel

  DashboardScreen({required this.label, this.toggleLocale});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<AlarmEntry> _alarms = []; // Liste aller aktiven Alarme
  String weatherDescription = ""; // Aktuelle Wetterbeschreibung
  String temperature = "--"; // Aktuelle Temperatur
  IconData weatherIcon = Icons.wb_cloudy; // Icon für das Wetter
  Timer? _weatherTimer; // Timer zum regelmäßigen Aktualisieren

  @override
  void initState() {
    super.initState();

    // Hört auf den Alarmstream und aktualisiert die Liste bei Änderungen
    MqttService().alarmStream.listen((alarms) {
      if (mounted) {
        setState(() {
          _alarms = alarms;
        });
      }
    });

    // Startet den Timer, um Wetterdaten alle 15 Minuten zu aktualisieren
    _weatherTimer = Timer.periodic(Duration(minutes: 15), (timer) => fetchWeather());
  }

  // Wird nach initState aufgerufen und hat Zugriff auf Kontext und Lokalisierung
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchWeather(); // Holt die Wetterdaten beim ersten Laden
  }

  @override
  void dispose() {
    _weatherTimer?.cancel(); // Stoppt den Timer beim Verlassen
    super.dispose();
  }

  // Holt aktuelle Wetterdaten abhängig von der Spracheinstellung
  Future<void> fetchWeather() async {
    final localeCode = Localizations.localeOf(context).languageCode;
    final langKey = 'lang_$localeCode';

    final url = Uri.parse('https://wttr.in/Koblenz?format=j1&lang=$localeCode');
    try {
      final response = await http.get(url, headers: {'User-Agent': 'Mozilla/5.0'});
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final current = data["current_condition"][0];
        final temp = current["temp_C"];
        final desc = current[langKey]?[0]?['value'] ?? current["weatherDesc"][0]["value"];

        // Wähle das passende Icon basierend auf der Beschreibung (mehrsprachig)
        IconData icon = Icons.wb_cloudy;
        final descLower = desc.toLowerCase();
        if (descLower.contains("sun") || descLower.contains("clear") || descLower.contains("sonne") || descLower.contains("klar")) {
          icon = Icons.wb_sunny;
        } else if (descLower.contains("cloud") || descLower.contains("wolke")) {
          icon = Icons.cloud;
        } else if (descLower.contains("rain") || descLower.contains("regen")) {
          icon = Icons.grain;
        } else if (descLower.contains("snow") || descLower.contains("schnee")) {
          icon = Icons.ac_unit;
        } else if (descLower.contains("storm") || descLower.contains("gewitter")) {
          icon = Icons.flash_on;
        }

        // Setzt die Wetteranzeige
        setState(() {
          weatherDescription = desc;
          temperature = "$temp°C";
          weatherIcon = icon;
        });
      } else {
        // Fehler beim Laden der Daten
        setState(() {
          weatherDescription = AppLocalizations.of(context)!.weatherError;
          temperature = "--";
          weatherIcon = Icons.error;
        });
      }
    } catch (e) {
      // Kein Zugriff auf Wetterdienst möglich
      setState(() {
        weatherDescription = AppLocalizations.of(context)!.weatherOffline;
        temperature = "--";
        weatherIcon = Icons.wifi_off;
      });
    }
  }

  // Öffnet ein Dialogfenster mit allen aktuellen Alarmen
  void _showAlarmDialog() {
    final loc = AppLocalizations.of(context)!;

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
              // Überschrift
              Text(
                loc.currentAlerts,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
              SizedBox(height: 12),

              // Liste der Alarme oder Hinweistext
              Expanded(
                child: _alarms.isEmpty
                    ? Center(
                        child: Text(
                          loc.noCriticalValues,
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _alarms.length,
                        separatorBuilder: (_, __) => SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final alarm = _alarms[index];
                          final matchingTopics = _alarms
                              .where((a) => a.sensorLabel == alarm.sensorLabel)
                              .map((a) => a.topic)
                              .toList();

                          final title = alarm.sensorLabel == 'Temperatur'
                              ? loc.alarmTitleTemperature
                              : loc.alarmTitleHumidity;

                          final value = alarm.value;

                          // Einzelne Alarmanzeige
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
                                        Text(title,
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                                        SizedBox(height: 4),
                                        Text(loc.alarmMessageValue(value),
                                            style: TextStyle(fontSize: 14, color: Colors.black54)),
                                        SizedBox(height: 4),
                                        Text(loc.topic(alarm.topic),
                                            style: TextStyle(fontSize: 12, color: Colors.black54)),
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

              // Schließen-Button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(loc.close, style: TextStyle(color: Colors.deepPurple, fontSize: 16)),
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
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Color(0xFF2C0D52),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(loc.dashboard, style: TextStyle(color: Colors.white, fontSize: 24)),
        actions: [
          // Wetteranzeige (Text + Icon)
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
          SizedBox(width: 10),

          // Sprachwechsel
          IconButton(
            icon: Icon(Icons.language, color: Colors.white),
            tooltip: loc.changeLanguage,
            onPressed: widget.toggleLocale,
          ),

          // Alarmglocke mit Indikator
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
                    decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: BoxConstraints(minWidth: 12, minHeight: 12),
                  ),
                ),
            ],
          ),
          SizedBox(width: 10),

          // Benutzer-Logout
          PopupMenuButton<String>(
            icon: Icon(Icons.person, color: Colors.white),
            offset: Offset(0, 40),
            onSelected: (value) async {
              if (value == 'logout') {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(toggleLocale: widget.toggleLocale),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'logout',
                child: Text(loc.logout),
              ),
            ],
            color: Colors.white,
          ),
          SizedBox(width: 20),
        ],
      ),

      // Hauptinhalt: Sensor-Karten + Filterbereich
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
          SensorSelectionSection(label: widget.label), // Gebäudewahl, Etage etc.
        ],
      ),
    );
  }
}
