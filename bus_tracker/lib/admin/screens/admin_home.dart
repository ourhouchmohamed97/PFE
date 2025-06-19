import 'dart:async';
import 'package:bus_tracker/admin/screens/add_vehicle.dart';
import 'package:bus_tracker/admin/screens/historique.dart';
import 'package:bus_tracker/admin/screens/notification.dart';
import 'package:bus_tracker/admin/screens/profile.dart';
import 'package:bus_tracker/admin/screens/setting.dart';
import 'package:bus_tracker/admin/screens/view_vehicle.dart';
// import 'package:bus_tracker/core/models/notifications_model.dart';
import 'package:bus_tracker/core/widgets/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});
 static StreamSubscription? _notificationSubscription;

 static Future<void> cancelNotificationListener() async {
  await _notificationSubscription?.cancel();
  _notificationSubscription = null;
}
  @override
  _ActiveVehiclesPageState createState() => _ActiveVehiclesPageState();
}

class _ActiveVehiclesPageState extends State<AdminHomePage> {
  int _selectedIndex = 0;

  GoogleMapController? _mapController;
  String? companyId;

  int _unreadCount = 0;
  Map<String, Marker> _vehicleMarkers = {}; // <-- To hold all vehicle markers
  StreamSubscription<DatabaseEvent>? _vehiclesSubscription;

  Future<void> loadCompanyId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final adminDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!adminDoc.exists) return;

      final data = adminDoc.data();
      if (data == null || data['companyId'] == null) return;

      setState(() {
        companyId = data['companyId'] as String;
      });
    } catch (e) {
      debugPrint('Failed to load company ID: $e');
    }
  }

  void _listenNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    AdminHomePage._notificationSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('targetAdminUid', isEqualTo: user.uid)
        .where('companyId', isEqualTo: companyId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      final unread = snapshot.docs.where((doc) => !(doc.data()['isRead'] ?? true)).length;

      if (mounted) {
        setState(() {
          _unreadCount = unread;
        });
      }
    });
  }

 void _listenVehicleLocations() {
  if (companyId == null) return;

  final vehiclesRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://bustracker-eabea-default-rtdb.europe-west1.firebasedatabase.app',
  ).ref('vehicles');

  _vehiclesSubscription = vehiclesRef.onValue.listen((event) {
    final vehiclesData = event.snapshot.value as Map<dynamic, dynamic>?;

    if (vehiclesData == null) return;

    final Map<String, Marker> newMarkers = {};

    vehiclesData.forEach((vehicleId, vehicleData) {
      if (vehicleData is Map &&
          vehicleData['companyId'] == companyId &&
          vehicleData.containsKey('location')) {
        final location = vehicleData['location'];
        if (location is Map &&
            location.containsKey('latitude') &&
            location.containsKey('longitude')) {
          final lat = (location['latitude'] as num).toDouble();
          final lng = (location['longitude'] as num).toDouble();

          final pos = LatLng(lat, lng);

          newMarkers[vehicleId] = Marker(
            markerId: MarkerId(vehicleId),
            position: pos,
            infoWindow: InfoWindow(title: "Vehicle $vehicleId"),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          );
        }
      }
    });

    if (mounted) {
      setState(() {
        _vehicleMarkers = newMarkers;
      });

      // Animate camera only if map controller is ready and markers exist
      if (_mapController != null && _vehicleMarkers.isNotEmpty) {
        final bounds = _createBoundsFromMarkers(_vehicleMarkers.values.toList());
        _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
      }
    }
  });
}


  @override
  void initState() {
    super.initState();
    loadCompanyId().then((_) {
      if (companyId != null) {
        _listenNotifications();
        _listenVehicleLocations(); // Start listening vehicle locations after companyId is loaded
      }
    });
  }

  @override
  void dispose() {
    _vehiclesSubscription?.cancel();
    AdminHomePage.cancelNotificationListener();
    _mapController?.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    Widget nextPage;

    switch (index) {
      case 1:
        nextPage = const VehicleTrackingPage();
        break;
      case 2:
        nextPage = const HistoryPage();
        break;
      case 3:
        nextPage = const SettingsPage();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextPage),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Color.fromARGB(255, 0, 0, 0)),
          onPressed: () {
            Navigator.pop(context);
          },
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
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsPage()),
                  );
                },
                icon: const Icon(Icons.notifications, color: Colors.grey),
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),

          // Profile icon
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfilePage(),
                ),
              );
            },
            child: const CircleAvatar(
              backgroundImage: AssetImage('assets/images/profile.png'),
            ),
          ),

          const SizedBox(width: 16),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
  initialCameraPosition: const CameraPosition(
    target: LatLng(0, 0), // or any default location
    zoom: 2, // zoomed out to show world, so user won't see empty space
  ),
  onMapCreated: (controller) {
    _mapController = controller;

    // After controller is ready, if you already have markers, center map:
    if (_vehicleMarkers.isNotEmpty) {
      final bounds = _createBoundsFromMarkers(_vehicleMarkers.values.toList());
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    }
  },
  markers: Set<Marker>.of(_vehicleMarkers.values),
  myLocationEnabled: true,
  myLocationButtonEnabled: false,
),


          // Floating location button
           Positioned(
          bottom: 100,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'btn_center_admin_location',
            onPressed: () {
              if (_vehicleMarkers.isEmpty) return;

              // Compute bounds for all vehicle markers
              LatLngBounds bounds = _createBoundsFromMarkers(_vehicleMarkers.values.toList());

              _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
            },
            backgroundColor: Colors.blue,
            tooltip: 'Center on all vehicles',
            child: const Icon(Icons.location_searching),
          ),
        ),

        // Bottom buttons for Add Vehicle and View Vehicle
        Positioned(
          bottom: 0, // just above BottomNavigationBar
          left: 0,
          right: 0,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 36),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AddCarPage()),
                        );
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Add Vehicle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(160, 60),
                        textStyle: const TextStyle(color: Colors.white, fontSize: 16),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const VehicleTrackingPage()),
                        );
                      },
                      icon: const Icon(Icons.list, color: Colors.white),
                      label: const Text('View Vehicles'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        minimumSize: const Size(160, 60),
                        textStyle: const TextStyle(color: Colors.white, fontSize: 16),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),

    bottomNavigationBar: BottomNavigationBar(
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Vehicles'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
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

/// Helper method to create LatLngBounds from markers list
LatLngBounds _createBoundsFromMarkers(List<Marker> markers) {
  assert(markers.isNotEmpty);
  double? x0, x1, y0, y1;
  for (final marker in markers) {
    final lat = marker.position.latitude;
    final lng = marker.position.longitude;
    if (x0 == null) {
      x0 = x1 = lat;
      y0 = y1 = lng;
    } else {
      if (lat < x0) x0 = lat;
      if (lat > x1!) x1 = lat;
      if (lng < y0!) y0 = lng;
      if (lng > y1!) y1 = lng;
    }
  }
  return LatLngBounds(southwest: LatLng(x0!, y0!), northeast: LatLng(x1!, y1!));
}
}