import 'package:flutter/material.dart';

class AirQualityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.purpleAccent,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Durchschnittliche Luftqualität",
              style: TextStyle(color: Colors.white, fontSize: 18)),
          Spacer(),
          Center(
            child: Text("3 AQI\nLow",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          Spacer(),
        ],
      ),
    );
  }
}
