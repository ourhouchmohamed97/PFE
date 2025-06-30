import 'dart:async';
import 'dart:ui' as ui;
import 'package:bus_tracker/admin/screens/setting.dart';
import 'package:bus_tracker/core/widgets/constants.dart';
import 'package:bus_tracker/driver/vehicleinfo.dart';
import 'package:bus_tracker/shared/pages/notification.dart';
import 'package:bus_tracker/admin/screens/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});
  static StreamSubscription? _notificationSubscription;

  static Future<void> cancelNotificationListener() async {
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
  }

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  int _selectedIndex = 0;
  GoogleMapController? _mapController;
  LatLng? _userLocation;
  StreamSubscription<Position>? _locationSubscription;
  BitmapDescriptor? _carIcon;
  String? _companyId;

  // Changed from final to nullable String for dynamic vehicle ID
  String? _vehicleId; 
  late DatabaseReference _vehicleRef;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCarIcon();
    _checkPermissionsAndStartTracking();
    _fetchCompanyIdAndInit();
    _fetchVehicleId(); // <-- fetch vehicleId dynamically here
    _listenNotifications();
  }

Future<void> _fetchVehicleId() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    // Query vehicles where driverId == current user's uid
    final querySnapshot = await FirebaseFirestore.instance
        .collection('vehicles')
        .where('assignedDriverId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      debugPrint("No vehicle assigned to this driver.");
      return;
    }

    final vehicleDoc = querySnapshot.docs.first;
    final fetchedVehicleId = vehicleDoc.id;

    if (mounted) {
      setState(() {
        _vehicleId = fetchedVehicleId;
        _vehicleRef = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: 'https://bustracker-eabea-default-rtdb.europe-west1.firebasedatabase.app',
        ).ref("vehicles/$_vehicleId");
      });

      _startListeningLocation(); // start only when vehicle ID is ready
    }
  } catch (e) {
    debugPrint('Error fetching vehicle for driver: $e');
  }
}


  Future<void> _fetchCompanyIdAndInit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return;

      final data = userDoc.data();
      if (data == null || data['companyId'] == null) return;

      _companyId = data['companyId'] as String;

      if (_vehicleId != null) {
        _vehicleRef = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL:
              'https://bustracker-eabea-default-rtdb.europe-west1.firebasedatabase.app',
        ).ref("vehicles/$_vehicleId");
      }

      await _loadCarIcon();
      await _checkPermissionsAndStartTracking();
    } catch (e) {
      debugPrint('Erreur récupération companyId: $e');
    }
  }

  Future<BitmapDescriptor> getResizedBitmapDescriptor(String path, int width, int height) async {
    final byteData = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(
      byteData.buffer.asUint8List(),
      targetWidth: width,
      targetHeight: height,
    );
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  Future<void> _loadCarIcon() async {
    _carIcon = await getResizedBitmapDescriptor('assets/images/Car Location.png', 100, 100);
  }

  Future<void> _checkPermissionsAndStartTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint("Location permission denied");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint("Location permission denied forever");
      return;
    }

    _startListeningLocation();
  }

  void _startListeningLocation() {
    if (_vehicleId == null) {
      debugPrint("Vehicle ID is null, cannot start location tracking");
      return;
    }

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      final newLocation = LatLng(position.latitude, position.longitude);

      final now = DateTime.now().toUtc();
      final dayKey = "${now.year.toString().padLeft(4, '0')}-"
          "${now.month.toString().padLeft(2, '0')}-"
          "${now.day.toString().padLeft(2, '0')}";
      final timestampKey = now.toIso8601String();

      final tripPointRef = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://bustracker-eabea-default-rtdb.europe-west1.firebasedatabase.app',
      ).ref("vehicles/$_vehicleId/trips/$dayKey/points/$timestampKey");

      _vehicleRef.set({
        "companyId": _companyId ?? "",
        "location": {
          "latitude": position.latitude,
          "longitude": position.longitude,
          "timestamp": timestampKey,
        }
      });

      tripPointRef.set({
        "latitude": position.latitude,
        "longitude": position.longitude,
        "timestamp": timestampKey,
      }).then((_) {
        debugPrint("Location and trip point updated: $newLocation");
      }).catchError((e) {
        debugPrint("Location update error: $e");
      });

      if (mounted) {
        setState(() {
          _userLocation = newLocation;
        });

        _mapController?.animateCamera(CameraUpdate.newLatLng(newLocation));
      }
    });
  }

  Future<void> _openVehicleInfoPage() async {
    if (_vehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No vehicle assigned')),
      );
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('vehicles').doc(_vehicleId).get();

      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle not found')),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const VehicleInfoPage(),
        ),
      );
    } catch (e) {
      debugPrint('Error fetching vehicle: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load vehicle info')),
      );
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController?.dispose();
    DriverHomePage.cancelNotificationListener();
    super.dispose();
  }

  void _listenNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DriverHomePage._notificationSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('targetUserUid', isEqualTo: user.uid)
        .where('companyId', isEqualTo: _companyId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      final unread = snapshot.docs
          .where((doc) => !(doc.data()['isRead'] ?? true))
          .length;

      if (mounted) {
        setState(() {
          _unreadCount = unread;
        });
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 1:
        _openVehicleInfoPage();
        break;
      case 2:
        // TODO: Implement History page navigation
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        );
        break;
      default:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                    MaterialPageRoute(builder: (_) => const NotificationsPage()),
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

          const SizedBox(width: 8),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _userLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _userLocation!,
                zoom: 15,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (controller) => _mapController = controller,
              markers: {
                Marker(
                  markerId: const MarkerId("vehicle"),
                  position: _userLocation!,
                  icon: _carIcon ?? BitmapDescriptor.defaultMarker,
                  infoWindow: const InfoWindow(title: "My Vehicle"),
                )
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_car), label: 'Vehicles'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
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
