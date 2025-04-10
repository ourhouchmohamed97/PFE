import 'package:bus_tracker/pages/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bus_tracker/pages/login.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ViewBuses extends StatefulWidget {
  const ViewBuses({super.key});

  @override
  _ViewBusesState createState() => _ViewBusesState();
}

class _ViewBusesState extends State<ViewBuses> {
  String userName = "Loading..."; // Default text before fetching data
  late GoogleMapController mapController;
  final LatLng _initialPosition = const LatLng(35.5713, -5.3724);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => userName = "Guest");
        return;
      }

      String email = user.email ?? "";
      if (email.isEmpty) {
        setState(() => userName = "No Email Found");
        return;
      }

      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(email).get();

      if (userDoc.exists) {
        Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('name')) {
          setState(() => userName = data['name'] ?? "No Name");
        } else {
          setState(() => userName = "Name not available");
        }
      } else {
        setState(() => userName = "Enter your name");
      }
    } catch (e) {
      print("Error fetching user name: $e");
      setState(() => userName = "Error Loading");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Colors.grey),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ProfilePage()),
                          );
                        },
                        child: const Text(
                          'View Profile',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: const Text('Nearby bus stops'),
                    onTap: () {},
                  ),
                  _customDivider(),
                  ListTile(
                    leading: const Icon(Icons.map_outlined),
                    title: const Text('View lines'),
                    onTap: () {},
                  ),
                  _customDivider(),
                  ListTile(
                    leading: const Icon(Icons.add_road),
                    title: const Text('Create route'),
                    onTap: () {},
                  ),
                  _customDivider(),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text('Change Language'),
                    onTap: () {},
                  ),
                  _customDivider(),
                  ListTile(
                    leading: const Icon(Icons.share),
                    title: const Text('Share app'),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            Image.asset('assets/images/darkCar.png', width: 100, height: 100),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(0, 86, 210, 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout, color: Colors.black, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 14.0,
              ),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: Image.asset(
                          'assets/images/menu.png',
                          width: 30,
                          height: 30,
                        ),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tap to add destination',
                    prefixIcon: const Icon(Icons.location_on,
                        color: Color.fromRGBO(255, 223, 0, 1)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: MediaQuery.of(context).size.width * 0.8,
                padding: const EdgeInsets.symmetric(vertical: 10),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(0, 86, 210, 1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: Image.asset(
                        'assets/images/distance.png',
                        width: 30,
                        height: 30,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Image.asset(
                        'assets/images/plus.png',
                        width: 30,
                        height: 30,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Image.asset(
                        'assets/images/partager.png',
                        width: 30,
                        height: 30,
                      ),
                      onPressed: () {
                        Share.share(
                          'Check out this awesome bus tracking app!',
                          subject: 'Bus Tracker App',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _customDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Align(
        alignment: Alignment.center,
        child: Container(
          width: 250,
          height: 1,
          color: Colors.grey[300],
        ),
      ),
    );
  }
}
