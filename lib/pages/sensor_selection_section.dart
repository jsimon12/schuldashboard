// Importiert notwendige Pakete und Abhängigkeiten
import 'package:flutter/material.dart';
import 'package:schuldashboard/l10n/app_localizations.dart';
import 'room_plan_screen.dart';

/// Widget für die untere Leiste mit Sensorauswahl-Buttons.
/// Zeigt vier Buttons: Licht, Temperatur, Luftfeuchtigkeit, Fenster.
class SensorSelectionSection extends StatelessWidget {
  final String label; // Wird derzeit nicht verwendet, aber für spätere Erweiterungen nützlich

  SensorSelectionSection({required this.label});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.purple.shade900,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSensorButton(context, Icons.lightbulb, loc.light),         // Licht
          _buildSensorButton(context, Icons.thermostat, loc.temperature),  // Temperatur
          _buildSensorButton(context, Icons.air, loc.humidity),            // Luftfeuchtigkeit
          _buildSensorButton(context, Icons.window, loc.window),           // Fenster/Rollläden
        ],
      ),
    );
  }

  /// Baut einen einzelnen Sensor-Button mit Icon und Text.
  /// Beim Klick wird zur `RoomPlanScreen` navigiert mit passendem Label.
  Widget _buildSensorButton(BuildContext context, IconData icon, String label) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white, size: 30),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RoomPlanScreen(label: label),
              ),
            );
          },
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}
