import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverWaitingForPermissionPage extends StatefulWidget {
  @override
  _DriverWaitingForPermissionPageState createState() => _DriverWaitingForPermissionPageState();
}

class _DriverWaitingForPermissionPageState extends State<DriverWaitingForPermissionPage> {
  bool? isApproved;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _checkApprovalStatus();
  }

  Future<void> _checkApprovalStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          error = 'No user logged in.';
          isLoading = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        setState(() {
          error = 'User data not found.';
          isLoading = false;
        });
        return;
      }

      final data = doc.data()!;
      // Assume you have an 'isApproved' boolean field in the user document
      setState(() {
        isApproved = data['isApproved'] ?? false;
        isLoading = false;
      });

      if (isApproved == true) {
        // Navigate to main driver screen, for example:
        Navigator.pushReplacementNamed(context, '/driverMainPage');
      }
    } catch (e) {
      setState(() {
        error = 'Error checking approval: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Waiting for Permission')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Waiting for Permission')),
        body: Center(child: Text(error!)),
      );
    }

    if (isApproved == false) {
      return Scaffold(
        appBar: AppBar(title: const Text('Waiting for Permission')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Your account is pending admin approval.\nPlease wait until your account is approved.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      );
    }

    // Just in case
    return Scaffold(
      appBar: AppBar(title: const Text('Waiting for Permission')),
      body: const Center(child: Text('Unexpected state')),
    );
  }
}
