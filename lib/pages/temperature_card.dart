import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class TemperatureCard extends StatefulWidget {
  @override
  _TemperatureCardState createState() => _TemperatureCardState();
}

class _TemperatureCardState extends State<TemperatureCard> {
  String? _selectedBuilding;
  String? _selectedFloor;
  String? _selectedRoom;

  List<String> _buildings = [];
  List<String> _floors = [];
  List<String> _rooms = [];

  List<_TempData> _chartData = [];
  bool _isLoading = false;
  bool _isFilterLoading = true;

  DateTime _startDate = DateTime.now().subtract(Duration(days: 7));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
  }

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

  Future<void> _loadChartData() async {
    if (_selectedBuilding == null ||
        _selectedFloor == null ||
        _selectedRoom == null) {
      setState(() {
        _chartData = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final query = FirebaseFirestore.instance
          .collection('sensor_data')
          .where('building', isEqualTo: _selectedBuilding)
          .where('floor', isEqualTo: _selectedFloor)
          .where('room', isEqualTo: _selectedRoom)
          .where('topic', isEqualTo:
              'cbssimulation/${_selectedBuilding!}/${_selectedFloor!}/${_selectedRoom!}/temp')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
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

      print("Geladene Datenpunkte: ${_chartData.length}");
    } catch (e) {
      print("Fehler beim Laden der Temperaturdaten: $e");
      setState(() {
        _isLoading = false;
        _chartData = [];
      });
    }
  }

  Future<void> _selectDateRange() async {
    final result = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 700), // Erweiterung hier
            child: Material(
              color: Colors.transparent,
              child: Theme(
                data: Theme.of(context).copyWith(
                  dialogBackgroundColor: Colors.deepPurple.shade300,
                  colorScheme: ColorScheme.light(
                    primary: Colors.deepPurple.shade600,
                    onPrimary: Colors.white,
                    onSurface: Colors.white,
                  ),
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                  ),
                ),
                child: DateRangePickerDialog(
                  initialDateRange: DateTimeRange(
                    start: _startDate,
                    end: _endDate,
                  ),
                  firstDate: DateTime.now().subtract(Duration(days: 365)),
                  lastDate: DateTime.now(),
                  initialEntryMode: DatePickerEntryMode.input,
                ),
              ),
            ),
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        _startDate = result.start;
        _endDate = result.end;
      });
      _loadChartData();
    }
  }

  String convertBuildingLabel(String val) {
    switch (val) {
      case 'building_a':
        return 'Gebäude A';
      case 'building_b':
        return 'Gebäude B';
      case 'building_c':
        return 'Gebäude C';
      default:
        return val;
    }
  }

  String convertFloorLabel(String val) {
    if (val == 'floor_e') return 'Etage E';
    final match = RegExp(r'floor_(\d+)').firstMatch(val);
    return match != null ? 'Etage ${match.group(1)}' : val;
  }

  String convertRoomLabel(String val) {
    final match = RegExp(r'room_0?(\d+)').firstMatch(val);
    return match != null ? 'Raum ${match.group(1)}' : val;
  }

  List<CartesianSeries<_TempData, DateTime>> _getSeriesData() {
    return [
      LineSeries<_TempData, DateTime>(
        dataSource: _chartData,
        xValueMapper: (data, _) => data.time,
        yValueMapper: (data, _) => data.value,
        name: 'Temperatur',
        color: Colors.orange,
        width: 2,
        markerSettings: MarkerSettings(isVisible: true),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
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
                    "Temperaturverlauf",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      _buildDropdown("Gebäude", _selectedBuilding, _buildings,
                          convertBuildingLabel, (val) {
                        setState(() {
                          _selectedBuilding = val;
                          _loadChartData();
                        });
                      }),
                      SizedBox(width: 12),
                      _buildDropdown("Etage", _selectedFloor, _floors,
                          convertFloorLabel, (val) {
                        setState(() {
                          _selectedFloor = val;
                          _loadChartData();
                        });
                      }),
                      SizedBox(width: 12),
                      _buildDropdown("Raum", _selectedRoom, _rooms,
                          convertRoomLabel, (val) {
                        setState(() {
                          _selectedRoom = val;
                          _loadChartData();
                        });
                      }),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _selectDateRange,
                        icon: Icon(Icons.date_range, color: Colors.white),
                        label: Text(
                          "Zeitraum wählen",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple.shade600,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "${DateFormat('dd.MM.yyyy').format(_startDate)} – ${DateFormat('dd.MM.yyyy').format(_endDate)}",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child:
                                CircularProgressIndicator(color: Colors.white))
                        : _selectedBuilding == null ||
                                _selectedFloor == null ||
                                _selectedRoom == null
                            ? Center(
                                child: Text("Bitte Filter auswählen",
                                    style: TextStyle(color: Colors.white70)))
                            : _chartData.isEmpty
                                ? Center(
                                    child: Text("Keine Daten verfügbar",
                                        style:
                                            TextStyle(color: Colors.white70)))
                                : SfCartesianChart(
                                    backgroundColor: Colors.deepPurple.shade400,
                                    primaryXAxis: DateTimeAxis(
                                      labelStyle:
                                          TextStyle(color: Colors.white),
                                      majorGridLines: MajorGridLines(width: 0),
                                    ),
                                    primaryYAxis: NumericAxis(
                                      labelStyle:
                                          TextStyle(color: Colors.white),
                                      majorGridLines: MajorGridLines(
                                          width: 0.2, color: Colors.white24),
                                    ),
                                    tooltipBehavior:
                                        TooltipBehavior(enable: true),
                                    legend: Legend(isVisible: false),
                                    series: _getSeriesData(),
                                  ),
                  ),
                ],
              ),
      ),
    );
  }

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
          enabledBorder:
              UnderlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
        ),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(labelFn(item),
                      style: TextStyle(color: Colors.white)),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _TempData {
  final DateTime time;
  final double value;

  _TempData({required this.time, required this.value});
}
