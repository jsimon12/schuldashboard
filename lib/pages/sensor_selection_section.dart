import 'package:flutter/material.dart';
import 'room_plan_screen.dart';

class SensorSelectionSection extends StatelessWidget {
  final String label;

  SensorSelectionSection({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.purple.shade900,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSensorButton(context, Icons.lightbulb, "Licht"),
          _buildSensorButton(context, Icons.thermostat, "Temperatur"),
          _buildSensorButton(context, Icons.air, "Luftqualität"),
          _buildSensorButton(context, Icons.window, "Fenster"),
        ],
      ),
    );
  }

  Widget _buildSensorButton(BuildContext context, IconData icon, String label) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white, size: 30),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => RoomPlanScreen(label: label)),
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
