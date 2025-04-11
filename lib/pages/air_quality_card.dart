// Importiert notwendige Bibliotheken für UI, Datenbank, Diagramme, Lokalisierung und Datum
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:schuldashboard/l10n/app_localizations.dart';

// Widget zur Anzeige der Luftfeuchtigkeit mit Filteroptionen und Diagramm
class AirQualityCard extends StatefulWidget {
  @override
  _AirQualityCardState createState() => _AirQualityCardState();
}

class _AirQualityCardState extends State<AirQualityCard> {
  // Auswahlfilter für Gebäude, Etage, Raum
  String? _selectedBuilding;
  String? _selectedFloor;
  String? _selectedRoom;

  // Optionen für Dropdowns
  List<String> _buildings = [];
  List<String> _floors = [];
  List<String> _rooms = [];

  // Diagrammdaten
  List<_HumidityData> _chartData = [];

  // Ladezustände
  bool _isLoading = false;
  bool _isFilterLoading = true;

  // Zeitbereich für die Abfrage
  DateTime _startDate = DateTime.now().subtract(Duration(days: 7));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadFilterOptions(); // Beim Start Filteroptionen aus Firestore laden
  }

  // Filterdaten aus Firestore holen und vorbereiten
  Future<void> _loadFilterOptions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('sensor_data')
          .limit(300)
          .get();

      final buildings = <String>{};
      final floors = <String>{};
      final rooms = <String>{};

      for (var doc in snapshot.docs) {
        buildings.add(doc['building']);
        floors.add(doc['floor']);
        rooms.add(doc['room']);
      }

      setState(() {
        _buildings = buildings.toList()..sort();
        _floors = floors.toList()..sort();
        _rooms = rooms.toList()..sort();
        _isFilterLoading = false;
      });
    } catch (e) {
      print("Fehler beim Laden der Filteroptionen: $e");
      setState(() => _isFilterLoading = false);
    }
  }

  // Holt Luftfeuchtigkeitsdaten basierend auf den Filtereinstellungen
  Future<void> _loadChartData() async {
    if (_selectedBuilding == null || _selectedFloor == null || _selectedRoom == null) {
      setState(() => _chartData = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final query = FirebaseFirestore.instance
          .collection('sensor_data')
          .where('building', isEqualTo: _selectedBuilding)
          .where('floor', isEqualTo: _selectedFloor)
          .where('room', isEqualTo: _selectedRoom)
          .where('topic', isEqualTo: 'cbssimulation/${_selectedBuilding!}/${_selectedFloor!}/${_selectedRoom!}/hum')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(_getEndOfDay(_endDate)))
          .limit(100);

      final snapshot = await query.get();

      // Wandelt die Daten in _HumidityData um
      final data = snapshot.docs
          .where((doc) => double.tryParse(doc['payload'].toString()) != null)
          .map((doc) => _HumidityData(
                time: (doc['timestamp'] as Timestamp).toDate(),
                value: double.parse(doc['payload']),
              ))
          .toList()
        ..sort((a, b) => a.time.compareTo(b.time));

      setState(() {
        _chartData = data;
        _isLoading = false;
      });
    } catch (e) {
      print("Fehler beim Laden der Luftfeuchtigkeitsdaten: $e");
      setState(() {
        _isLoading = false;
        _chartData = [];
      });
    }
  }

  // Gibt den Tagesendzeitpunkt zurück (z.B. 23:59:59)
  DateTime _getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  // Öffnet Date-Picker für Datumsbereich
  Future<void> _selectDateRange() async {
    DateTimeRange? result = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.input,
      locale: Locale(AppLocalizations.of(context)!.localeName),
    );

    if (result != null) {
      setState(() {
        _startDate = result.start;
        _endDate = result.end;
      });
      _loadChartData(); // Daten neu laden
    }
  }

  // Umwandlung technischer Label in benutzerfreundlichen Text mit Lokalisierung
  String convertBuildingLabel(String val) {
    switch (val) {
      case 'building_a':
        return '${AppLocalizations.of(context)!.building} A';
      case 'building_b':
        return '${AppLocalizations.of(context)!.building} B';
      case 'building_c':
        return '${AppLocalizations.of(context)!.building} C';
      default:
        return val;
    }
  }

  String convertFloorLabel(String val) {
    if (val == 'floor_e') return '${AppLocalizations.of(context)!.floor} E';
    final match = RegExp(r'floor_(\d+)').firstMatch(val);
    return match != null ? '${AppLocalizations.of(context)!.floor} ${match.group(1)}' : val;
  }

  String convertRoomLabel(String val) {
    final match = RegExp(r'room_0?(\d+)').firstMatch(val);
    return match != null ? '${AppLocalizations.of(context)!.room} ${match.group(1)}' : val;
  }

  // Erstellt die Diagrammreihe
  List<CartesianSeries<_HumidityData, DateTime>> _getSeriesData() {
    return [
      LineSeries<_HumidityData, DateTime>(
        dataSource: _chartData,
        xValueMapper: (data, _) => data.time,
        yValueMapper: (data, _) => data.value,
        name: AppLocalizations.of(context)!.humidity,
        color: Colors.cyan,
        width: 2,
        markerSettings: MarkerSettings(isVisible: true),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Card(
      color: Colors.deepPurple.shade400,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isFilterLoading
            ? Center(child: CircularProgressIndicator(color: Colors.white))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Überschrift
                  Text(
                    loc.humidity,
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),

                  // Dropdowns für Gebäude, Etage und Raum
                  Row(
                    children: [
                      _buildDropdown(loc.building, _selectedBuilding, _buildings, convertBuildingLabel, (val) {
                        setState(() {
                          _selectedBuilding = val;
                          _loadChartData();
                        });
                      }),
                      SizedBox(width: 12),
                      _buildDropdown(loc.floor, _selectedFloor, _floors, convertFloorLabel, (val) {
                        setState(() {
                          _selectedFloor = val;
                          _loadChartData();
                        });
                      }),
                      SizedBox(width: 12),
                      _buildDropdown(loc.room, _selectedRoom, _rooms, convertRoomLabel, (val) {
                        setState(() {
                          _selectedRoom = val;
                          _loadChartData();
                        });
                      }),
                    ],
                  ),
                  SizedBox(height: 10),

                  // Datumsbereichs-Auswahl
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _selectDateRange,
                        icon: Icon(Icons.date_range, color: Colors.white),
                        label: Text(loc.selectDateRange, style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple.shade600,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          "${DateFormat('dd.MM.yyyy').format(_startDate)} – ${DateFormat('dd.MM.yyyy').format(_endDate)}",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Diagramm oder Ladehinweise
                  Expanded(
                    child: _isLoading
                        ? Center(child: CircularProgressIndicator(color: Colors.white))
                        : _selectedBuilding == null || _selectedFloor == null || _selectedRoom == null
                            ? Center(child: Text(loc.pleaseSelectFilter, style: TextStyle(color: Colors.white70)))
                            : _chartData.isEmpty
                                ? Center(child: Text(loc.noData, style: TextStyle(color: Colors.white70)))
                                : SfCartesianChart(
                                    backgroundColor: Colors.deepPurple.shade400,
                                    primaryXAxis: DateTimeAxis(
                                      labelStyle: TextStyle(color: Colors.white),
                                      majorGridLines: MajorGridLines(width: 0),
                                    ),
                                    primaryYAxis: NumericAxis(
                                      labelStyle: TextStyle(color: Colors.white),
                                      majorGridLines: MajorGridLines(width: 0.2, color: Colors.white24),
                                    ),
                                    tooltipBehavior: TooltipBehavior(enable: true),
                                    legend: Legend(isVisible: false),
                                    series: _getSeriesData(),
                                  ),
                  ),
                ],
              ),
      ),
    );
  }

  // Baut ein Dropdown-Feld mit dynamischen Werten
  Widget _buildDropdown(
    String hint,
    String? value,
    List<String> items,
    String Function(String) labelFn,
    void Function(String?) onChanged,
  ) {
    return Expanded(
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: Colors.deepPurple.shade300,
        decoration: InputDecoration(
          labelText: hint,
          labelStyle: TextStyle(color: Colors.white),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
        ),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(labelFn(item), style: TextStyle(color: Colors.white)),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// Datenmodell für Diagrammpunkte (Zeit + Wert)
class _HumidityData {
  final DateTime time;
  final double value;

  _HumidityData({required this.time, required this.value});
}
