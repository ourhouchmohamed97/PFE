import 'package:bus_tracker/admin/screens/about_us.dart';
import 'package:bus_tracker/admin/screens/add_pyment.dart';
import 'package:bus_tracker/admin/screens/privacy_policy.dart';
import 'package:bus_tracker/admin/screens/subscrib_plan.dart';
import 'package:bus_tracker/admin/screens/term_condition.dart';
import 'package:bus_tracker/driver/driver_home.dart';
import 'package:bus_tracker/driver/vehicleinfo.dart';
import 'package:bus_tracker/shared/pages/d_login_Page.dart';
import 'package:bus_tracker/admin/screens/edit_profile.dart';
import 'package:bus_tracker/admin/screens/admin_home.dart';
import 'package:bus_tracker/admin/screens/view_vehicle.dart';
import 'package:bus_tracker/core/widgets/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatefulWidget {
  
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? userRole;
  bool _darkModeEnabled = false;
  bool _pushNotificationsEnabled = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> getUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'Unknown User';
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['name'] ?? 'No Name';
  }

   String? companyId;// User's temporary selection
  Future<void> loadCompanyId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final adminDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
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
   @override
  void initState() {
    super.initState();
    loadUserRole();
    loadCompanyId();
  }
  Future<void> loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!doc.exists) return;
      setState(() {
        userRole = doc.data()?['role'] ?? 'driver'; // Par défaut 'driver'
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement du rôle utilisateur: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
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

          // Main Content
          Padding(
            padding: const EdgeInsets.only(top: 100),
            child: ListView(
              padding: const EdgeInsets.all(30),
              children: [
                // 👤 Dynamic Profile Section
                FutureBuilder<String>(
                  future: getUserName(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            backgroundImage: AssetImage('assets/images/profile.png'),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            snapshot.data ?? 'No Name',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  },
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
                  'Upgrade to premium',
                   onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SubscriptionPlanPage()),
                    );
                  },),
                _buildListTile('Add a payment method'
                    , onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AddPaymentMethodPage(companyId: companyId ?? '')),
                      );
                    },),

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

                _buildListTile(
                  'About us',
                   onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const  AboutUsPage()),
                    );
                  },),
       
                _buildListTile(
                  'Privacy policy',
                   onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const  PrivacyPolicyPage()),
                    );
                  },),
               _buildListTile(
                  'Privacy policy',
                   onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const  TermsConditionsPage()),
                    );
                  },),

                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await AdminHomePage.cancelNotificationListener(); 
                      await _auth.signOut();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('You have been signed out successfully!')),
                        );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error signing out: $e')),
                        );
                      }
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
                    backgroundColor: blueColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 4,
                    shadowColor: Colors.black.withOpacity(0.2),
                  ),
                ),
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
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Vehicles'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        onTap: (index) {
          if (userRole == 'admin') {
            switch (index) {
              case 0:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminHomePage()),
                );
                break;
              case 1:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const VehicleTrackingPage()),
                );
                break;
              case 2:
                // TODO: admin history page
                break;
              case 3:
                // Already on settings, do nothing or refresh
                break;
            }
          } else if (userRole == 'driver') {
            switch (index) {
              case 0:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const DriverHomePage()),
                );
                break;
              case 1:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const VehicleInfoPage()),
                );
                break;
              case 2:
                // TODO: driver history page
                break;
              case 3:
                // Already on settings, do nothing or refresh
                break;
            }
          } else {
            // Role pas encore chargé ou inconnu, peut-être afficher un message ou loader
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User role loading, please wait...')),
            );
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
