import 'package:bus_tracker/admin/screens/setting.dart';
import 'package:bus_tracker/core/models/vehicule_model.dart';
import 'package:bus_tracker/driver/driver_home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VehicleInfoPage extends StatefulWidget {
  const VehicleInfoPage({super.key});

  @override
  State<VehicleInfoPage> createState() => _VehicleInfoPageState();
}

class _VehicleInfoPageState extends State<VehicleInfoPage> {
  Vehicle? _vehicle;
  bool _isLoading = true;
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _fetchAssignedVehicle();
  }

 Future<void> _fetchAssignedVehicle() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('vehicles')
        .where('assignedDriverId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final vehicleDoc = querySnapshot.docs.first;
      setState(() {
        _vehicle = Vehicle.fromMap(vehicleDoc.data());
        _isLoading = false;
      });
    } else {
      debugPrint('No vehicle assigned to this driver.');
      setState(() => _isLoading = false);
    }
  } catch (e) {
    debugPrint("Error loading vehicle: $e");
    setState(() => _isLoading = false);
  }
}

  Future<void> _sendAlertToAdmin(String alertType) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || _vehicle == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final companyId = userDoc.data()?['companyId'];
      if (companyId == null) return;

      final adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('companyId', isEqualTo: companyId)
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();

      if (adminSnapshot.docs.isEmpty) return;
      final adminId = adminSnapshot.docs.first.id;

      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'Alerte véhicule',
        'description':
            'Alerte "$alertType" envoyée pour ${_vehicle!.brand} (${_vehicle!.matricule})',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'userId': adminId,
        'iconData': 'warning',
        'iconColor': 'orange',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Alerte envoyée : $alertType')),
        );
      }
    } catch (e) {
      debugPrint("Erreur d'envoi d'alerte : $e");
    }
  }

  Widget _buildInfoItem(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent),
          const SizedBox(width: 10),
          Text(
            "$title:",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _vehicle!.photosURL.isNotEmpty
                ? Image.network(
                    _vehicle!.photosURL.first,
                    height: 150,
                    width: 200,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    'assets/images/AudiQ3.png',
                    height: 150,
                    width: 200,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(height: 16),
          _buildInfoItem('Brand', _vehicle!.brand, Icons.directions_car),
          _buildInfoItem('Model / Type',
              "${_vehicle!.model} / ${_vehicle!.type}", Icons.car_repair),
          _buildInfoItem(
              'Year', _vehicle!.year.toString(), Icons.calendar_today),
          _buildInfoItem(
              'Matricule', _vehicle!.matricule, Icons.numbers_rounded),
        ],
      ),
    );
  }

  Widget _buildAlertSelector() {
    final alerts = ['Low Fuel', 'Maintenance Due', 'Flat Tire', 'Engine Issue'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Send Alert',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...alerts.map(
          (alert) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 0),
            leading:
                const Icon(Icons.warning, color: Colors.orange, size: 22),
            title: Text(alert, style: const TextStyle(fontSize: 14)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _sendAlertToAdmin(alert),
          ),
        ),
      ],
    );
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DriverHomePage()),
        );
        break;
      case 1:
        break;
      case 2:
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        );
        break;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_vehicle == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Vehicle'),
          backgroundColor: Colors.blueAccent,
        ),
        body: const Center(
          child: Text("No vehicle assigned to your account.",
              style: TextStyle(fontSize: 16)),
        ),
        bottomNavigationBar: _buildBottomBar(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${_vehicle!.brand} ${_vehicle!.model}'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVehicleSection(),
            const SizedBox(height: 24),
            const Divider(thickness: 1),
            const SizedBox(height: 12),
            _buildAlertSelector(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  BottomNavigationBar _buildBottomBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.directions_car), label: 'Vehicles'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
      onTap: _onItemTapped,
    );
  }
}
