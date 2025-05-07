import 'package:flutter/material.dart';
import 'package:bus_tracker/screens/b_welcome_Page.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  void initState() {
    super.initState();
    // Navigate to the Welcome page after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const Welcome()),
      );
    });
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
                      'CarTrack',
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
     
     