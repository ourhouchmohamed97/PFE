import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssignDriverDropdown extends StatefulWidget {
  final String companyId;
  final TextEditingController controller;

  const AssignDriverDropdown({
    Key? key,
    required this.companyId,
    required this.controller,
  }) : super(key: key);

  @override
  State<AssignDriverDropdown> createState() => _AssignDriverDropdownState();
}

class _AssignDriverDropdownState extends State<AssignDriverDropdown> {
  List<Map<String, dynamic>> _drivers = [];
  String? _selectedDriverId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDrivers();
  }

  Future<void> fetchDrivers() async {
  try {
    print('Fetching drivers for companyId: ${widget.companyId}');
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'driver')
        .where('status', isEqualTo: 'approved')
        .where('companyId', isEqualTo: widget.companyId)
        .get();

    print('Drivers fetched: ${snapshot.docs.length}');

    final drivers = snapshot.docs.map((doc) {
      final data = doc.data();
      print('Driver: ${data['name']}');
      return {
        'uid': doc.id,
        'name': data['name'] ?? 'No Name',
      };
    }).toList();

    setState(() {
      _drivers = drivers;
      _isLoading = false;
    });
  } catch (e) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load drivers: $e')),
    );
  }
}

@override
void didUpdateWidget(covariant AssignDriverDropdown oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (oldWidget.companyId != widget.companyId && widget.companyId.isNotEmpty) {
    fetchDrivers();
  }
}


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Assign a Driver',
        border: OutlineInputBorder(),
      ),
      value: _selectedDriverId,
      items: _drivers.map((driver) {
        return DropdownMenuItem<String>(
          value: driver['uid'],
          child: Text(driver['name']),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedDriverId = value;
          widget.controller.text = value ?? '';
        });
      },
    );
  }
}
