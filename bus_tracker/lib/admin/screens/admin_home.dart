import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:bus_tracker/admin/screens/add_vehicle.dart';
import 'package:bus_tracker/admin/screens/historique.dart';
import 'package:bus_tracker/shared/pages/notification.dart';
import 'package:bus_tracker/admin/screens/profile.dart';
import 'package:bus_tracker/admin/screens/setting.dart';
import 'package:bus_tracker/admin/screens/view_vehicle.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
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
    BitmapDescriptor? _carIcon;
  int _unreadCount = 0;
  Map<String, Marker> _vehicleMarkers = {}; // <-- To hold all vehicle markers
  StreamSubscription<DatabaseEvent>? _vehiclesSubscription;
 
 
 Future<BitmapDescriptor> _getCustomCarIcon() async {
  final ByteData byteData = await rootBundle.load('assets/images/Car Location.png');
  final codec = await ui.instantiateImageCodec(
    byteData.buffer.asUint8List(),
    targetWidth: 100,
    targetHeight: 100,
  );
  final frame = await codec.getNextFrame();
  final ByteData? resizedImageData =
      await frame.image.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.fromBytes(resizedImageData!.buffer.asUint8List());
}
  

Future<void> _loadCarIcon() async {
  _carIcon = await _getCustomCarIcon();
}

  Future<void> loadCompanyId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
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
      final unread =
          snapshot.docs.where((doc) => !(doc.data()['isRead'] ?? true)).length;

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

  _vehiclesSubscription = vehiclesRef.onValue.listen((event) async {
    final vehiclesData = event.snapshot.value as Map<dynamic, dynamic>?;

    if (vehiclesData == null) return;

    final Map<String, Marker> newMarkers = {};

    for (var entry in vehiclesData.entries) {
      final vehicleId = entry.key;
      final vehicleData = entry.value;

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

          // 🔄 Fetch brand/model from Firestore using vehicleId
          try {
            final doc = await FirebaseFirestore.instance
                .collection('vehicles')
                .doc(vehicleId)
                .get();

            String vehicleName = 'Vehicle';
            if (doc.exists) {
              final data = doc.data();
              final brand = data?['brand'] ?? '';
              final model = data?['model'] ?? '';
              vehicleName = '$brand $model'.trim();
            }

            newMarkers[vehicleId] = Marker(
              markerId: MarkerId(vehicleId),
              position: pos,
              infoWindow: InfoWindow(title: vehicleName),
              icon: _carIcon ?? BitmapDescriptor.defaultMarker, // Use custom icon here
            );

            if (mounted) {
              setState(() {
                _vehicleMarkers = newMarkers;
              });
            }
          } catch (e) {
            print('Error fetching vehicle info from Firestore: $e');
          }
        }
      }
    }

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

  _loadCarIcon().then((_) async {
    await loadCompanyId();  // Your async function to get companyId
    if (companyId != null) {
      _listenVehicleLocations();
      _listenNotifications();
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
          'HayMobility',
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
              target: LatLng(
                  33.5899, -7.6039), // Start somewhere neutral like Casablanca
              zoom: 5.5, // Wide view initially
            ),
            onMapCreated: (controller) async {
              _mapController = controller;

              // Step 1: show wide zoom first
              await _mapController!.animateCamera(
                CameraUpdate.newCameraPosition(
                  const CameraPosition(
                    target: LatLng(33.5899, -7.6039),
                    zoom: 5.5,
                  ),
                ),
              );

              await Future.delayed(const Duration(seconds: 2));

              // Step 2: zoom into vehicle(s)
              if (_vehicleMarkers.length == 1) {
                final marker = _vehicleMarkers.values.first;
                await _mapController!.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: marker.position,
                      zoom: 12.5, // Adjust to see city
                    ),
                  ),
                );
              } else if (_vehicleMarkers.length > 1) {
                final bounds =
                    _createBoundsFromMarkers(_vehicleMarkers.values.toList());
                await _mapController!
                    .animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
              }
            },
            markers: Set<Marker>.of(_vehicleMarkers.values),
            
             myLocationEnabled: true,  
             myLocationButtonEnabled: false,
          ),

          Positioned(
  bottom: 50,
  left: 16, // 👈 This makes it appear on the **left**
  child: FloatingActionButton(
    heroTag: 'btn_my_location',
    backgroundColor: Colors.white,
    onPressed: () async {
      // Try to get current location
      final position = await Geolocator.getCurrentPosition();
      final target = LatLng(position.latitude, position.longitude);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 14));
    },
    child: const Icon(Icons.my_location, color: Colors.blue),
  ),
),

    
    ],
  ),

  // Centered FloatingActionButton
  floatingActionButton: FloatingActionButton(
    heroTag: 'btn_add_vehicle',
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddCarPage()),
      );
    },
    backgroundColor: Colors.blue,
    tooltip: 'Add Vehicle',
    child: const Icon(Icons.add),
  ),
  floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

  // Bottom App Bar
  bottomNavigationBar: BottomAppBar(
    color: Colors.white,
    shape: const CircularNotchedRectangle(),
    notchMargin: 6,
    elevation: 8,
    child: SizedBox(
      height: 58,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(icon: Icons.home, label: "Home", index: 0),
          _buildNavItem(icon: Icons.directions_car, label: "Vehicles", index: 1),
          const SizedBox(width: 48), // Space for FAB
          _buildNavItem(icon: Icons.history, label: "History", index: 2),
          _buildNavItem(icon: Icons.settings, label: "Settings", index: 3),
        ],
      ),
    ),
  ));
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
    return LatLngBounds(
        southwest: LatLng(x0!, y0!), northeast: LatLng(x1!, y1!));
  }
Widget _buildNavItem({required IconData icon, required String label, required int index}) {
  final isSelected = _selectedIndex == index;

  return GestureDetector(
    onTap: () => _onItemTapped(index),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.grey,
            fontSize: 11,
          ),
        ),
      ],
    ),
  );
}

}
