import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:irrigation/utils/prefs.dart';
import 'package:irrigation/utils/shared.dart';
import 'package:irrigation/utils/stat_card.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AnalyticsPage extends StatefulWidget {
  final Function(bool) isHideBottomNavBar;

  const AnalyticsPage({Key? key, required this.isHideBottomNavBar}) : super(key: key);

  @override
  _AnalyticsPageState createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  DatabaseReference _databaseReference = FirebaseDatabase.instance.ref('FirebaseIOT');
  Map<dynamic, dynamic>? firebaseData;
  String? selectedUnit;

  Map<String, dynamic> _data = {
    'historicalData': {
      'temperature': <SensorData>[],
      'humidity': <SensorData>[],
      'soilMoisture': <SensorData>[],
    },
    'temperature': {
      'current': 0.0,
      'average': 0.0,
      'highest': 0.0,
      'lowest': 0.0,
    },
    'humidity': {
      'current': 0.0,
      'average': 0.0,
      'highest': 0.0,
      'lowest': 0.0,
    },
    'soilMoisture': {
      'current': 0.0,
      'average': 0.0,
      'highest': 0.0,
      'lowest': 0.0,
    },
  };

  @override
  void initState() {
    super.initState();
    initFirebase();
    loadAllUnits();
    fetchData();
  }
  List<String> units = [];

  Future<void> initFirebase() async {
    _databaseReference = FirebaseDatabase.instance.ref("FirebaseIOT");
    // Set up a listener for changes in the sprinkler state
  }

  Future<void> listenDb(String unit) async {
    _clearData();
    _databaseReference.child(unit).keepSynced(true);
    _databaseReference.child(unit).onValue.listen((DatabaseEvent event) {
      final dynamic snapshotValue = event.snapshot.value;
      if (snapshotValue != null && snapshotValue is Map<dynamic, dynamic>) {
        firebaseData = snapshotValue; // Assign Firebase data to firebaseData

        // Fetch data when new data is received
        fetchData();
      } else {
        print('Invalid snapshot value or null data received');
      }
    });
  }

  Future<void> loadAllUnits() async {
    String? savedUnit = await AppPrefs().getSelectedUnit();
    final devices = await AppPrefs().getDevices();
    setState(() {
      units = List.generate(devices.length, (index) => devices[index]['id']);
      selectedUnit = savedUnit ?? units[0];
      listenDb(selectedUnit!);
    });
  }

  Future<List<DropdownMenuItem<String>>> _buildDropdownItems() async {
    // show units as Unit 1, Unit 2, etc.
    return List.generate(units.length, (index) {
      return DropdownMenuItem<String>(
        value: units[index],
        child: Text('Unit ${index + 1}'),
      );
    });
  }

  Future<void> fetchData() async {
    try {
      if (firebaseData != null) {
        final Map<dynamic, dynamic>? historyData = firebaseData?['history'];
        print('History Data');
        print(historyData);

        if (historyData != null && historyData.isNotEmpty) {
          print('History Data is not empty');
          // Clear existing data before updating
          _clearData();

          // Process the history data
          historyData.forEach((key, value) {
            double timestamp = double.parse(key.toString());
            DateTime dateTime = DateTime.fromMicrosecondsSinceEpoch((timestamp * 1000000).toInt());
            double humidity = double.parse(value['humidity'].toString());
            double soilMoisture = double.parse(value['soilMoisture'].toString());
            double temperature = double.parse(value['temperature'].toString());

            // Update the data for each type (Temperature, Soil Moisture, Humidity)
            _updateData('temperature', dateTime, temperature);
            _updateData('humidity', dateTime, humidity);
            _updateData('soilMoisture', dateTime, soilMoisture);
          });
          print('hdshsf ${historyData.values.toList()}');
        }
        setState(() {});
      }
    } catch (error) {
      print('Error fetching data: $error');
    }

    setState(() {});
  }

  // Helper method to clear existing data
  void _clearData() {
    _data = {
      'historicalData': {
        'temperature': <SensorData>[],
        'humidity': <SensorData>[],
        'soilMoisture': <SensorData>[],
      },
      'temperature': {
        'current': 0.0,
        'average': 0.0,
        'highest': 0.0,
        'lowest': 0.0,
      },
      'humidity': {
        'current': 0.0,
        'average': 0.0,
        'highest': 0.0,
        'lowest': 0.0,
      },
      'soilMoisture': {
        'current': 0.0,
        'average': 0.0,
        'highest': 0.0,
        'lowest': 0.0,
      },
    };
  }

  // Helper method to update data for each type (Temperature, Soil Moisture, Humidity)
  void _updateData(String type, DateTime dateTime, double value) {
    List<SensorData> historicalData = _data['historicalData'][type];
    historicalData.add(SensorData(dateTime, value));

    _data[type]['current'] = value;
    _data[type]['average'] = _calculateAverage(historicalData.map((e) => e.value).toList());
    _data[type]['highest'] = _calculateHighest(historicalData.map((e) => e.value).toList());
    _data[type]['lowest'] = _calculateLowest(historicalData.map((e) => e.value).toList());

    print(_data);
  }

  // Helper method to calculate average
  double _calculateAverage(List<double> data) {
    if (data.isEmpty) return 0.0;
    return data.reduce((a, b) => a + b) / data.length;
  }

  // Helper method to calculate highest
  double _calculateHighest(List<double> data) {
    if (data.isEmpty) return 0.0;
    return data.reduce((a, b) => a > b ? a : b);
  }

  // Helper method to calculate lowest
  double _calculateLowest(List<double> data) {
    if (data.isEmpty) return 0.0;
    return data.reduce((a, b) => a < b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    print(_data);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Temperature'),
              Tab(text: 'Soil Moisture'),
              Tab(text: 'Humidity'),
            ],
          ),
          title: const Text('Analytics'),
          actions: [
            FutureBuilder(future: _buildDropdownItems(), builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                print(snapshot.data);
                return DropdownButtonHideUnderline(
                  child: ConstrainedBox(
                    constraints:  const BoxConstraints(maxWidth: 130),
                    child: DropdownButton(
                      value: selectedUnit,
                      items: snapshot.data,
                      onChanged: (value) {
                        setState(() {
                          selectedUnit = value!;
                          AppPrefs().saveSelectedUnit(value);

                          listenDb(selectedUnit!);
                        });
                      },
                    ),
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            }),
          ],
        ),
        body: TabBarView(
          children: [
            _buildChartTab('Temperature', _data['historicalData']['temperature'], 'temperature', Icons.thermostat),
            _buildChartTab('Soil Moisture', _data['historicalData']['soilMoisture'], 'soilMoisture', Icons.water_drop),
            _buildChartTab('Humidity', _data['historicalData']['humidity'], 'humidity', Icons.cloud_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildChartTab(String title, List<SensorData> data, type, icon) {
    if (data.isEmpty) {
      // Handle the case when data is not available yet
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const Gap(20.0),
            Text('Fetching $title data...'),
          ],
        )
      );
    }

    var myData = data.where((element) => element.time.day == data.reduce((a, b) => a.time.day > b.time.day ? a : b).time.day).toList();
    myData.sort((a, b) => a.time.compareTo(b.time));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            primary: true,
            shrinkWrap: true,
            crossAxisCount: 2,
            children: [
              StatCard(title: 'Current', value: _data[type]['current'].toStringAsFixed(2), icon: icon),
              StatCard(title: 'Average', value: _data[type]['average'].toStringAsFixed(2), icon: icon),
              StatCard(title: 'Highest', value: _data[type]['highest'].toStringAsFixed(2), icon: icon),
              StatCard(title: 'Lowest', value: _data[type]['lowest'].toStringAsFixed(2), icon: icon),
            ],
          ),
          const Gap(40.0),
          Text('Today\'s $title', style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
          SfCartesianChart(
            primaryXAxis: DateTimeAxis(
              dateFormat: DateFormat.Hms(),
              intervalType: DateTimeIntervalType.hours,
              majorGridLines: const MajorGridLines(width: 0),
            ),
            primaryYAxis: const NumericAxis(
              axisLine: AxisLine(width: 0),
              majorTickLines: MajorTickLines(size: 0),
              minorTickLines: MinorTickLines(size: 0),
              majorGridLines: MajorGridLines(width: 0),
            ),
            series: <CartesianSeries<SensorData, DateTime>>[
              LineSeries<SensorData, DateTime>(
                dataSource: myData,
                xValueMapper: (SensorData sensorData, _) => sensorData.time,
                yValueMapper: (SensorData sensorData, _) => sensorData.value,
                dataLabelSettings: const DataLabelSettings(isVisible: false),
                enableTooltip: true,
                markerSettings: const MarkerSettings(isVisible: false),
              ),
            ],
            tooltipBehavior: TooltipBehavior(enable: true),
          ),
          Gap(24)
        ],
      ),
    );
  }
}

class SensorData {
  final DateTime time;
  final double value;

  SensorData(this.time, this.value);
}
