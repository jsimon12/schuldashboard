// Imports für UI, Firebase Firestore, Diagramme, Datum und Lokalisierung
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:schuldashboard/l10n/app_localizations.dart';

/// Widget zum Anzeigen historischer Temperaturdaten als Diagramm mit Filteroptionen.
class TemperatureCard extends StatefulWidget {
  @override
  _TemperatureCardState createState() => _TemperatureCardState();
}

class _TemperatureCardState extends State<TemperatureCard> {
  // Auswahlfilter für Gebäude, Etage und Raum
  String? _selectedBuilding;
  String? _selectedFloor;
  String? _selectedRoom;

  // Listen mit allen verfügbaren Filteroptionen
  List<String> _buildings = [];
  List<String> _floors = [];
  List<String> _rooms = [];

  // Daten für das Diagramm
  List<_TempData> _chartData = [];
  bool _isLoading = false;
  bool _isFilterLoading = true;

  // Zeitspanne für die Abfrage (letzte 7 Tage)
  DateTime _startDate = DateTime.now().subtract(Duration(days: 7));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadFilterOptions(); // Lade mögliche Filter aus der Datenbank
  }

  /// Lade verfügbare Gebäude-, Etagen- und Raumoptionen
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

  /// Lade Temperaturdaten aus Firestore basierend auf Auswahl und Zeitraum
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
          .where('topic', isEqualTo: 'cbssimulation/${_selectedBuilding!}/${_selectedFloor!}/${_selectedRoom!}/temp')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(_getEndOfDay(_endDate)))
          .limit(100);

      final snapshot = await query.get();

      final data = snapshot.docs
          .where((doc) => double.tryParse(doc['payload'].toString()) != null)
          .map((doc) => _TempData(
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
      print("Fehler beim Laden der Temperaturdaten: $e");
      setState(() {
        _isLoading = false;
        _chartData = [];
      });
    }
  }

  /// Hilfsfunktion: gibt das Tagesende (23:59:59) zurück
  DateTime _getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Öffnet einen DateRangePicker zur Auswahl eines Zeitbereichs
  Future<void> _selectDateRange() async {
    DateTimeRange? result = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.input,
      locale: Localizations.localeOf(context),
    );

    if (result != null) {
      setState(() {
        _startDate = result.start;
        _endDate = result.end;
      });
      _loadChartData();
    }
  }

  // Umwandlung interner Codes in beschriftete Texte (abhängig von Sprache)
  String convertBuildingLabel(String val, AppLocalizations loc) {
    switch (val) {
      case 'building_a': return "${loc.building} A";
      case 'building_b': return "${loc.building} B";
      case 'building_c': return "${loc.building} C";
      default: return val;
    }
  }

  String convertFloorLabel(String val, AppLocalizations loc) {
    if (val == 'floor_e') return "${loc.floor} E";
    final match = RegExp(r'floor_(\d+)').firstMatch(val);
    return match != null ? "${loc.floor} ${match.group(1)}" : val;
  }

  String convertRoomLabel(String val, AppLocalizations loc) {
    final match = RegExp(r'room_0?(\d+)').firstMatch(val);
    return match != null ? "${loc.room} ${match.group(1)}" : val;
  }

  /// Liefert die Datenreihen für das Temperaturdiagramm
  List<CartesianSeries<_TempData, DateTime>> _getSeriesData(AppLocalizations loc) {
    return [
      LineSeries<_TempData, DateTime>(
        dataSource: _chartData,
        xValueMapper: (data, _) => data.time,
        yValueMapper: (data, _) => data.value,
        name: loc.temperature,
        color: Colors.orange,
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
                  Text(
                    loc.temperature,
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  // Dropdowns zur Filterauswahl
                  Row(
                    children: [
                      _buildDropdown(loc.building, _selectedBuilding, _buildings,
                          (val) => convertBuildingLabel(val, loc), (val) {
                        setState(() {
                          _selectedBuilding = val;
                          _loadChartData();
                        });
                      }),
                      SizedBox(width: 12),
                      _buildDropdown(loc.floor, _selectedFloor, _floors,
                          (val) => convertFloorLabel(val, loc), (val) {
                        setState(() {
                          _selectedFloor = val;
                          _loadChartData();
                        });
                      }),
                      SizedBox(width: 12),
                      _buildDropdown(loc.room, _selectedRoom, _rooms,
                          (val) => convertRoomLabel(val, loc), (val) {
                        setState(() {
                          _selectedRoom = val;
                          _loadChartData();
                        });
                      }),
                    ],
                  ),
                  SizedBox(height: 10),
                  // Datumsauswahl
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
                          DateFormat('dd.MM.yyyy').format(_startDate) +
                              " – " +
                              DateFormat('dd.MM.yyyy').format(_endDate),
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Diagramm oder Hinweistext
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
                                    series: _getSeriesData(loc),
                                  ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Universeller Dropdown-Builder
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

/// Datenmodell für ein Temperatur-Messpunkt im Diagramm
class _TempData {
  final DateTime time;
  final double value;

  _TempData({required this.time, required this.value});
}
