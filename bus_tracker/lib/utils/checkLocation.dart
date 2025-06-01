import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

Future<void> checkLocationServices(BuildContext context) async {
  bool serviceEnabled;
  LocationPermission permission;

  // Check if location services are enabled
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Show alert if disabled
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Location Required'),
        content: Text('Please enable GPS to continue.'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
            child: Text('Open Settings'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
    return;
  }

  // Check permission
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are still denied
      return;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are permanently denied
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Location permissions are permanently denied'),
    ));
    return;
  }

  // If everything is OK, get position
  Position position = await Geolocator.getCurrentPosition();
  print("Location: ${position.latitude}, ${position.longitude}");
}
