// import 'package:bus_tracker/admin/screens/admin_home.dart';
import 'package:bus_tracker/driver/permission_waiting.dart';
import 'package:bus_tracker/shared/pages/redirect_by_role.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bus_tracker/shared/pages/b_welcome_Page.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  HomepageState createState() => HomepageState();
}
class HomepageState extends State<Homepage> {
  @override
  void initState() {
    super.initState();
    _navigateUser();
  }
  

  Future<void> _navigateUser() async {
    await Future.delayed(const Duration(seconds: 4));

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // No user signed in, go to welcome
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const  Welcome()),
      );
    } else {
      // User is signed in, fetch user role from Firestore
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!doc.exists || !doc.data()!.containsKey('role')) {
        // Role not found or invalid user document
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Welcome()),
        );
        return;
      }

      final role = doc['role'];

      Widget nextPage;
      if (role == 'admin') {
        nextPage = const Welcome();
      } else if (role == 'driver') {
        nextPage =  DriverWaitingForPermissionPage();
      } else {
        nextPage = const Welcome(); // fallback
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => nextPage),
      );
    }
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background Image
            Positioned(
              child: Image.asset(
                'assets/images/bg.png',
                width: double.infinity,
                height: double.infinity, // Replace with your image asset
                fit: BoxFit.cover, // Ensures the image covers the entire screen
              ),
            ),

            // Content Layer: Positioned Widgets, Text, and other UI components
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 80), // Adds space from the top

                  // Widget 1 - First Text
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'Welcome!',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 180),
                  Container(
                    width: 146,
                    height: 146,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(0, 86, 210, 1),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Image.asset(
                      'assets/images/whiteCar.png',
                      width: 111,
                      height: 111,
                    ),
                  ),

                  // Adds flexible space between widgets

                  // Widget 3 - Text "TRIPS"
                  const Padding(
                    padding: EdgeInsets.all(15.0),
                    child: Text(
                      'HayMobility',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
            
                ],
              ),
            ),
          ],
        )
      )
    );
  }
}
     
     