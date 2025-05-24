import 'dart:async';
import 'package:bus_tracker/models/vehicule_model.dart';
import 'package:bus_tracker/screens/home.dart';
import 'package:bus_tracker/screens/notification.dart';
import 'package:bus_tracker/screens/profile.dart';
import 'package:bus_tracker/screens/setting.dart';
import 'package:bus_tracker/utils/checkLocation.dart';
import 'package:bus_tracker/widgets/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class VehicleTrackingPage extends StatefulWidget {
  const VehicleTrackingPage({super.key});

  @override
  _VehicleTrackingPageState createState() => _VehicleTrackingPageState();
}

class _VehicleTrackingPageState extends State<VehicleTrackingPage> {
  int _selectedIndex = 1;
  LatLng? _userLocation;
  GoogleMapController? _mapController;
  Vehicle? _selectedVehicle;
  StreamSubscription? _vehicleSubscription;

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
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_userLocation!),
      );
    } catch (e) {
      print("Error getting location: $e");
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
          MaterialPageRoute(builder: (_) => const ActiveVehiclesPage()),
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


  List<Vehicle> _vehicles = [];
  void _listenToUserVehicles() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _vehicleSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('vehicles')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final vehicles = snapshot.docs
          .map((doc) => Vehicle.fromMap(doc.id, doc.data()))
          .toList();

      if (mounted) {
        setState(() {
          _vehicles = vehicles;
        });
      }
    });
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
              Navigator.pushReplacement(
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
              backgroundImage: AssetImage('assets/images/zaz.png'),
            ),
          ),
          const SizedBox(width: 16),
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
                  child: _vehicles.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: _vehicles.length,
                          itemBuilder: (context, index) {
                            final vehicle = _vehicles[index];
                            return Padding(
                              padding:
                                  EdgeInsets.only(top: index == 0 ? 16.0 : 0),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedVehicle = vehicle;
                                  });
                                },
                                child: Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                  shadowColor: Colors.black.withAlpha((0.1 * 255).toInt()),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 16),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: vehicle.photosURL.isNotEmpty
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
                                              Text(
                                                vehicle.brand,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${vehicle.type} • ${vehicle.year}',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 16,
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
                        builder: (_) =>
                            _buildConnectionSheet(_selectedVehicle!),
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
                          'Connect with "${_selectedVehicle!.type}"',
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

Widget _buildConnectionSheet(Vehicle vehicle) {
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

                    // Show first photo if exists, else a placeholder
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
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          'Type: ${vehicle.type}, Year: ${vehicle.year}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        Text(
                          'Matricule: ${vehicle.matricule}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              const SizedBox(height: 16),
              // Remove battery section (no battery info in your model)
              // If you want, you can add placeholder or remove it entirely

              // For demonstration, let's skip it

              const Divider(height: 32),
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.blue),
                  const SizedBox(width: 12),
                  const Text('Want to connect with driver?'),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      _showDriverConnectionSheet(context, vehicle);
                    },
                    child: const Text('Connect now'),
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

void _showDriverConnectionSheet(BuildContext context, Vehicle vehicle) {
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
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: vehicle.photosURL.isNotEmpty
                    ? NetworkImage(vehicle.photosURL.first)
                    : const AssetImage('assets/images/default_car.png')
                        as ImageProvider,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vehicle.matricule,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(vehicle.type,
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // You don't have driverName or rating, so remove this row or add placeholders
          // Example placeholders:
          const Row(
            children: [
              Text("Driver: John Doe",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              SizedBox(width: 8),
              Icon(Icons.star, color: Colors.amber, size: 18),
              Text("4.8"),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
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
              const SizedBox(width: 10),
              const CircleAvatar(
                backgroundColor: Color(0xFFEFEFEF),
                child: Icon(Icons.phone, color: Colors.black),
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
                    // Your call logic here
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
