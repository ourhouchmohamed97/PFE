import 'dart:math';
import 'package:bus_tracker/admin/screens/admin_home.dart';
import 'package:bus_tracker/admin/screens/setting.dart';
import 'package:bus_tracker/admin/screens/view_vehicle.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  DateTimeRange? selectedDateRange;
  List<DateTime> dateRangeDays = [];

  int total = 0;
  int active = 0;
  int inactive = 0;
  int driverCount = 0;

  List<FlSpot> vehicleDataSpots = [];

  @override
  void initState() {
    super.initState();
    _fetchVehicleCounts();
    _fetchDriverCount();
    _setDefaultDates();
  }

  void _setDefaultDates() {
    final today = DateTime.now();
    dateRangeDays = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    _generateGraphData();
  }

 void _generateGraphData() {
  final rand = Random();
  vehicleDataSpots = List.generate(
    dateRangeDays.length,
    (i) => FlSpot(
      i.toDouble(),
      rand.nextInt(7).toDouble(), // values between 0 and 6 inclusive
    ),
  );
  setState(() {});
}

  Future<void> _fetchVehicleCounts() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('vehicles').get();
      final vehicles = snapshot.docs;

      int totalCount = vehicles.length;
      int activeCount = vehicles.where((doc) {
        final data = doc.data();
        return data['status'] == 'active';
      }).length;

      if (mounted) {
        setState(() {
          total = totalCount;
          active = activeCount;
          inactive = totalCount - activeCount;
        });
        _generateGraphData(); // Regenerate chart with updated total
      }
    } catch (e) {
      print('Error fetching vehicle counts: $e');
    }
  }

  Future<void> _fetchDriverCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'driver')
          .get();

      if (mounted) {
        setState(() {
          driverCount = snapshot.size;
        });
      }
    } catch (e) {
      print('Error fetching drivers: $e');
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
        final totalDays = picked.end.difference(picked.start).inDays + 1;
        dateRangeDays = List.generate(totalDays, (i) => picked.start.add(Duration(days: i)));
        _generateGraphData();
      });
    }
  }

  Widget _buildSummaryCard(String title, int count, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rangeText = selectedDateRange != null
        ? '${DateFormat('MMM d').format(selectedDateRange!.start)} → ${DateFormat('MMM d').format(selectedDateRange!.end)}'
        : 'Last 7 Days';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        actions: [
          IconButton(icon: const Icon(Icons.date_range), onPressed: _pickDateRange),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(rangeText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),

          // Line Chart
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: total.toDouble() + 2,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < dateRangeDays.length) {
                          final date = dateRangeDays[index];
                          return Text(
                            DateFormat('MM/dd').format(date),
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    spots: vehicleDataSpots,
                    color: Colors.blue,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.3)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSummaryCard('Total', total, Colors.blue),
              _buildSummaryCard('Active', active, Colors.green),
              _buildSummaryCard('Inactive', inactive, Colors.red),
              _buildSummaryCard('Drivers', driverCount, Colors.orange),
            ],
          ),

          const SizedBox(height: 30),
          const Text('Vehicle Logs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) => ListTile(
                leading: const Icon(Icons.directions_bus, color: Colors.blue),
                title: Text('Vehicle #$index'),
                subtitle: const Text('Active from June 17, 2025'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ),
          ),
        ]),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Vehicles'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminHomePage()));
              break;
            case 1:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VehicleTrackingPage()));
              break;
            case 2:
              break;
            case 3:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
              break;
          }
        },
      ),
    );
  }
}
