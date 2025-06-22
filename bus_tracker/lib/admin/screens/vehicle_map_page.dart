import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart'; // only if needed

class VehicleMapPage extends StatefulWidget {
  final String vehicleId;
  final String vehicleName;

  const VehicleMapPage({
    Key? key,
    required this.vehicleId,
    required this.vehicleName,
  }) : super(key: key);

  @override
  _VehicleMapPageState createState() => _VehicleMapPageState();
}

class _VehicleMapPageState extends State<VehicleMapPage> {
  LatLng? _vehicleLocation;
  DatabaseReference? _vehicleRef;

  @override
  void initState() {
    super.initState();

    _vehicleRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://bustracker-eabea-default-rtdb.europe-west1.firebasedatabase.app',
    ).ref('vehicles/${widget.vehicleId}/location');

    _vehicleRef!.onValue.listen((event) {
      final location = event.snapshot.value as Map<dynamic, dynamic>?;

      if (location != null &&
          location.containsKey('latitude') &&
          location.containsKey('longitude')) {
        final lat = (location['latitude'] as num).toDouble();
        final lng = (location['longitude'] as num).toDouble();

        setState(() {
          _vehicleLocation = LatLng(lat, lng);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Localisation de ${widget.vehicleName}')),
      body: _vehicleLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _vehicleLocation!,
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('vehicle'),
                  position: _vehicleLocation!,
                  infoWindow: InfoWindow(title: widget.vehicleName),
                ),
              },
            ),
    );
  }
}
