import 'dart:async';
import 'package:bus_tracker/core/models/vehicule_model.dart';
import 'package:bus_tracker/admin/screens/admin_home.dart';
import 'package:bus_tracker/admin/screens/notification.dart';
import 'package:bus_tracker/admin/screens/profile.dart';
import 'package:bus_tracker/admin/screens/setting.dart';
import 'package:bus_tracker/core/utils/checkLocation.dart';
import 'package:bus_tracker/core/widgets/constants.dart';
import 'package:bus_tracker/shared/pages/call.dart';
import 'package:bus_tracker/shared/pages/chat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class VehicleTrackingPage extends StatefulWidget {
  const VehicleTrackingPage({super.key});

  @override
  VehicleTrackingPageState createState() => VehicleTrackingPageState();
}

class VehicleTrackingPageState extends State<VehicleTrackingPage> {
  int _selectedIndex = 1;
  LatLng? _userLocation;
  GoogleMapController? _mapController;
  Vehicle? _selectedVehicle;
  StreamSubscription? _vehicleSubscription;
  String? driverName;
  String? driverEmail;
  String? driverPhone;
  String? assignedDriverId;
  String? currentCompanyId;

  String? currentVehicleId;

  bool isLoadingDriver = false;

Future<void> _assignDriver(String driverId) async {
  final vehicleId = currentVehicleId;

  try {
    final vehicleRef = FirebaseFirestore.instance.collection('vehicles').doc(vehicleId);
    final driverRef = FirebaseFirestore.instance.collection('users').doc(driverId);

    // Reset previous driver if needed
    if (assignedDriverId != null && assignedDriverId != driverId) {
      await FirebaseFirestore.instance.collection('users').doc(assignedDriverId).update({
        'vehicleId': null,
      });
    }

    // Update vehicle with driverId
    await vehicleRef.update({
      'assignedDriverId': driverId,
    });

    // Update driver with vehicleId
    await driverRef.update({
      'vehicleId': vehicleId,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Conducteur affecté avec succès.')),
    );

    setState(() {
      assignedDriverId = driverId;
    });
  } catch (e) {
    debugPrint('Erreur d\'affectation: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Erreur lors de l\'affectation du conducteur.')),
    );
  }
}
  Future<void> fetchDriverInfo(String driverId) async {
    setState(() {
      isLoadingDriver = true;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(driverId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          driverName = data['name'] ?? 'No name';
          driverEmail = data['email'] ?? 'No email';
          driverPhone = data['phone'] ?? 'No phone';
        });
      } else {
        setState(() {
          driverName = 'Driver not found';
          driverEmail = '';
          driverPhone = '';
        });
      }
    } catch (e) {
      setState(() {
        driverName = 'Error loading driver';
        driverEmail = '';
        driverPhone = '';
      });
    } finally {
      setState(() {
        isLoadingDriver = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return;
      }

      LocationSettings locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
      );

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_userLocation!),
      );
    } catch (e) {
      // Replace print with proper logging in production
      debugPrint("Error getting location: $e");
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHomePage()),
        );
        break;
      case 1:
        // Already on Vehicles page
        break;
      case 2:
        // No history page added
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SettingsPage()),
        );
        break;
    }
  }

  bool _isLoading = true;
  List<Vehicle> _vehicles = [];

  void _listenToUserVehicles() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userData = userDoc.data();
    if (userData == null) return;

    final role = userData['role'];
    final companyId = userData['companyId'];

    Query vehiclesQuery;

    if (role == 'admin') {
      vehiclesQuery = FirebaseFirestore.instance
          .collection('vehicles')
          .where('companyId', isEqualTo: companyId)
          .orderBy('createdAt', descending: true);
    } else if (role == 'driver') {
      vehiclesQuery = FirebaseFirestore.instance
          .collection('vehicles')
          .where('driverId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true);
    } else {
      return;
    }

    _vehicleSubscription = vehiclesQuery.snapshots().listen((snapshot) {
      final vehicles = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Vehicle.fromMap(data);
      }).toList();

      if (mounted) {
        setState(() {
          _vehicles = vehicles;
          _isLoading = false;
        });
      }
    });
  }

  void _selectVehicle(Vehicle vehicle) {
    setState(() {
      _selectedVehicle = vehicle;
    });

    if (vehicle.assignedDriverId != null &&
        vehicle.assignedDriverId!.isNotEmpty) {
      fetchDriverInfo(vehicle.assignedDriverId!);
    } else {
      // Reset driver info if no driver assigned
      setState(() {
        driverName = 'No driver assigned';
        driverEmail = '';
        driverPhone = '';
      });
    }
  }

Future<void> _showDriverSelectionDialog() async {
  final admin = FirebaseAuth.instance.currentUser;
  if (admin == null) return;

  // Get admin's companyId
  final adminDoc = await FirebaseFirestore.instance.collection('users').doc(admin.uid).get();
  final companyId = adminDoc.data()?['companyId'];
  if (companyId == null) return;

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'driver')
        .where('status', isEqualTo: 'approved')
        .where('companyId', isEqualTo: companyId)
        .get();

    final drivers = snapshot.docs;

    // Now show dialog with list of drivers
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select a Driver'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final driver = drivers[index];
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(driver['name'] ?? 'No name'),
                subtitle: Text(driver['email'] ?? ''),
                onTap: () {
                  Navigator.pop(context);
                  _assignDriver(driver.id);
                },
              );
            },
          ),
        ),
      ),
    );
  } catch (e) {
    debugPrint('Error fetching drivers: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to load drivers.')),
    );
  }
}

  @override
  void initState() {
    super.initState();
    

    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkLocationServices(context);
      _getCurrentLocation();
      _listenToUserVehicles(); // start real-time updates
      _onItemTapped(_selectedIndex);
      
    });
  }

  @override
  void dispose() {
    _vehicleSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'CarTrack',
          style: GoogleFonts.lato(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              );
            },
            icon: const Icon(Icons.notifications, color: Colors.grey),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            child: const CircleAvatar(
              backgroundImage: AssetImage('assets/images/profile.png'),
            ),
          ),
          const SizedBox(width: 18),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 🔴 Map Section
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _userLocation ?? const LatLng(35.5713, -5.3724),
                        zoom: 14.0,
                      ),
                      onMapCreated: (controller) => _mapController = controller,
                      markers: {
                        if (_userLocation != null)
                          Marker(
                            markerId: const MarkerId('userLocation'),
                            position: _userLocation!,
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueBlue),
                            infoWindow:
                                const InfoWindow(title: "Your Location"),
                          )
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: FloatingActionButton(
                        onPressed: _getCurrentLocation,
                        backgroundColor: Colors.white,
                        child:
                            const Icon(Icons.my_location, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),

              // 🟨 Vehicle Cards Section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _vehicles.isEmpty
                          ? const Center(child: Text('No vehicles found.'))
                          : ListView.builder(
                              itemCount: _vehicles.length,
                              itemBuilder: (context, index) {
                                final vehicle = _vehicles[index];
                                return Padding(
                                  padding: EdgeInsets.only(
                                      top: index == 0 ? 16.0 : 0),
                                  child: GestureDetector(
                                    onTap: () => _selectVehicle(vehicle),
                                    child: Card(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 4,
                                      shadowColor: Colors.black
                                          .withAlpha((0.1 * 255).toInt()),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            const SizedBox(width: 16),
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child:
                                                  vehicle.photosURL.isNotEmpty
                                                      ? Image.network(
                                                          vehicle.photosURL[0],
                                                          width: 40,
                                                          height: 40,
                                                          fit: BoxFit.cover,
                                                        )
                                                      : Image.asset(
                                                          'assets/images/car1.png',
                                                          width: 40,
                                                          height: 40,
                                                        ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // First line: Brand and Type side by side
                                                  Row(
                                                    children: [
                                                      Text(
                                                        vehicle.brand,
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 8,
                                                                vertical: 4),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors
                                                              .blue.shade100,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        child: Text(
                                                          vehicle.type,
                                                          style: TextStyle(
                                                            color: Colors
                                                                .blue.shade700,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),

                                                  const SizedBox(height: 8),

                                                  // Second line: Matricule
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 12,
                                                        vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.grey.shade200,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                    ),
                                                    child: Text(
                                                      'Matricule: ${vehicle.matricule}',
                                                      style: TextStyle(
                                                        color: Colors
                                                            .grey.shade800,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 14,
                                                        letterSpacing: 1.1,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ),
            ],
          ),

          // 🔵 Booking Button
          if (_selectedVehicle != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Connect button with custom background color
                  ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => _buildConnectionSheet(
                          _selectedVehicle!,
                          driverName: driverName,
                          driverEmail: driverEmail,
                          driverPhone: driverPhone,
                          onAssignDriver: () {
                            _showDriverSelectionDialog();
                          },
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.transparent, // Remove default bg color
                      elevation: 0, // Remove default shadow
                      padding: EdgeInsets
                          .zero, // Remove default padding for Ink decoration
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        constraints: const BoxConstraints(minHeight: 56),
                        child: Text(
                          'Connect with "${_selectedVehicle!.brand}"',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Cancel (X) button - positioned top right with shadow
                  Positioned(
                    top: -12,
                    right: -12,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 4,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          setState(() {
                            _selectedVehicle = null;
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Vehicles',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: blueColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        showSelectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }
}

// when you click on connect with a car this what you will see in the page!

Widget _buildConnectionSheet(
  Vehicle vehicle, {
  required String? driverName,
  required String? driverEmail,
  required String? driverPhone,
  required VoidCallback onAssignDriver,
}) {
  return DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.65,
    minChildSize: 0.4,
    maxChildSize: 0.9,
    builder: (context, scrollController) {
      return SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      height: 4,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Connecting you to a car',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    vehicle.photosURL.isNotEmpty
                        ? Image.network(
                            vehicle.photosURL.first,
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: const Icon(Icons.directions_car, size: 40),
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              const Text('Car details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.directions_car, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${vehicle.brand} ${vehicle.model}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildInfoRow(Icons.category, 'Type', vehicle.type),
                        _buildInfoRow(Icons.calendar_today, 'Year',
                            vehicle.year.toString()),
                        _buildInfoRow(Icons.confirmation_number, 'Matricule',
                            vehicle.matricule),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: 32),

              const Text('Driver info',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.person, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driverName ?? 'No driver assigned',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if ((driverEmail ?? '').isNotEmpty)
                          _buildInfoRow(Icons.email, 'Email', driverEmail!),
                        if ((driverPhone ?? '').isNotEmpty)
                          _buildInfoRow(Icons.phone, 'Phone', driverPhone!),

                        const SizedBox(height: 12),

                        ElevatedButton.icon(
                          onPressed: onAssignDriver,
                          icon: const Icon(Icons.person_add),
                          label: Text(
                            vehicle.assignedDriverId == null
                                ? 'Assign Driver'
                                : 'Change Driver',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                vehicle.assignedDriverId == null
                                    ? Colors.green
                                    : Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: 32),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.blue),
                      SizedBox(width: 12),
                      Text('Want to connect with driver?'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        _showDriverConnectionSheet(
                          context,
                          vehicle,
                          driverName ?? '',
                        );
                      },
                      child: const Text('Connect now'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel Connection"),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildInfoRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

void _showDriverConnectionSheet(
    BuildContext context, Vehicle vehicle, String driverName) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 5,
            width: 40,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Connecting to driver",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text("Available",
                    style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            children: [
              Text("Driver: $driverName",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              const Icon(Icons.star, color: Colors.amber, size: 18),
              const Text("4.8"),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChatPage()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat, color: Colors.grey),
                        SizedBox(width: 8),
                        Text("Chat with driver"),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                  ),
                  child: const Text("Cancel Connection"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CallPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Call driver"),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
