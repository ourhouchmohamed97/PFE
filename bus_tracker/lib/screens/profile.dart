import 'package:bus_tracker/screens/d_login_Page.dart';
import 'package:bus_tracker/screens/edit_profile.dart';
import 'package:bus_tracker/screens/home.dart';
import 'package:bus_tracker/screens/setting.dart';
import 'package:bus_tracker/screens/view_vehicle.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bus_tracker/widgets/constants.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        selectedItemColor: Colors.grey,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Vehicles'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ActiveVehiclesPage()),
              );
              break;
            case 1:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VehicleTrackingPage()));
              break;
            case 2:
              // Replace with your History page
              // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HistoryPage()));
              break;
            case 3:
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
              break;
          }
        },
      ),
      body: Column(
        children: [
          // 🔷 Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 90, 24, 50),
            decoration: const BoxDecoration(
              color: blueColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.person, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 👤 Profile Card (Taller & Detailed)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            elevation: 3,
            child: const Padding(
              padding: EdgeInsets.all(24.0), // Extra padding
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundImage: AssetImage('assets/images/profile.png'),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'mohamed ourhouch',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Administrator',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ℹ️ Info Card (Taller)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            elevation: 3,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 22, horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    icon: Icons.email,
                    title: 'Email Address',
                    value: 'john.doe@example.com',
                  ),
                  SizedBox(height: 12),
                  Center(
                    child: SizedBox(
                      width: 250, // Short divider
                      child: Divider(color: Colors.grey),
                    ),
                  ),
                  SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.phone,
                    title: 'Phone Number',
                    value: '+1 (555) 123-4567',
                  ),
                  SizedBox(height: 12),
                  Center(
                    child: SizedBox(
                      width: 250,
                      child: Divider(color: Colors.grey),
                    ),
                  ),
                  SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.calendar_today,
                    title: 'Membership Date',
                    value: 'Joined: March 2023',
                  ),
                  SizedBox(height: 12),
                  Center(
                    child: SizedBox(
                      width: 250,
                      child: Divider(color: Colors.grey),
                    ),
                  ),
                  SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.person_outline,
                    title: 'Account Type',
                    value: 'Administrator',
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // 🔘 Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'logout',
                      style: TextStyle(
                          color: Color.fromARGB(255, 30, 30, 30),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const EditProfilePage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blueColor,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'edit',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 🔹 Refined Info Row
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
