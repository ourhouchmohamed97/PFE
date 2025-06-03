import 'package:bus_tracker/shared/pages/d_login_Page.dart';
import 'package:bus_tracker/admin/screens/edit_profile.dart';
import 'package:bus_tracker/admin/screens/admin_home.dart';
import 'package:bus_tracker/admin/screens/view_vehicle.dart';
import 'package:bus_tracker/core/widgets/constants.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkModeEnabled = false;
  bool _pushNotificationsEnabled = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 🔵 Blue Header
          Container(
            height: 150,
            color: blueColor,
            padding: const EdgeInsets.only(top: 30, left: 16),
            child: const Row(
              children: [
                Icon(Icons.settings, color: Colors.white, size: 26),
                SizedBox(width: 10),
                Text(
                  'Settings',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // 🧾 Main Content
          Padding(
            padding: const EdgeInsets.only(top: 100),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 👤 Profile Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage:
                            AssetImage('assets/images/profile.png'),
                      ),
                      SizedBox(width: 16),
                      Text(
                        'mohamed ourhouch',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('Account Settings',
                      style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 8),

                _buildListTile(
                  'Edit profile',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EditProfilePage()),
                    );
                  },
                ),
                _buildListTile(
                  'Change password',
                  // onTap: () {
                  //   Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //         builder: (context) => const ChangePasswordPage()),
                  //   );
                  // },
                ),
                _buildListTile(
                  'Add a payment method',
                  // onTap: () {
                  //   Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //         builder: (context) => const AddPaymentMethodPage()),
                  //   );
                  // },
                ),

                SwitchListTile(
                  title: const Text('Push notifications'),
                  value: _pushNotificationsEnabled,
                  onChanged: (value) {
                    setState(() => _pushNotificationsEnabled = value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Dark mode'),
                  value: _darkModeEnabled,
                  onChanged: (value) {
                    setState(() => _darkModeEnabled = value);
                  },
                ),

                const Divider(),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('More',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),

                _buildListTile('About us'),
                _buildListTile('Privacy policy'),
                _buildListTile('Terms and conditions'),

                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await _auth.signOut();
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('You have been signed out successfully!')),
                      );
                      Navigator.pushReplacement(
                        // ignore: use_build_context_synchronously
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()),
                      );
                    } catch (e) {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error signing out: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, size: 20, color: Colors.white),
                  label: const Expanded(
                    child: Text(
                      'Sign Out',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blueColor, // Vibrant blue background
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12), // Rounded corners
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 16), // Vertical padding
                    elevation: 4, // Shadow effect
                    // ignore: deprecated_member_use
                    shadowColor: Colors.black.withOpacity(0.2), // Subtle shadow
                  ),
                )
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_car), label: 'Vehicles'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AdminHomePage()),
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
              // Already on Settings, do nothing or pop to top
              break;
          }
        },
      ),
    );
  }

  ListTile _buildListTile(String title, {VoidCallback? onTap}) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
      onTap: onTap ?? () {},
    );
  }
}
