import 'package:bus_tracker/admin/screens/historique.dart';
import 'package:bus_tracker/admin/screens/view_vehicle.dart';
import 'package:bus_tracker/core/models/admin_model.dart';
import 'package:bus_tracker/core/models/driver_model.dart';
import 'package:bus_tracker/driver/driver_home.dart';
import 'package:bus_tracker/shared/pages/d_login_Page.dart';
import 'package:bus_tracker/admin/screens/edit_profile.dart';
import 'package:bus_tracker/admin/screens/admin_home.dart';
import 'package:bus_tracker/admin/screens/setting.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_tracker/core/widgets/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/user_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserModel? currentUser;
  bool isLoading = true;
  String? companyName;
  String? companyCode;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final role = userData['role'];

      UserModel? user;

      String? fetchedCompanyName;
      String? fetchedCompanyCode;

      if (role == 'admin') {
        final companyId = userData['companyId'];

        if (companyId != null) {
          final companyDoc = await FirebaseFirestore.instance
              .collection('companies')
              .doc(companyId)
              .get();
          print('Company document exists: ${companyDoc.exists}');
          print('Company data: ${companyDoc.data()}');
          if (companyDoc.exists) {
            final companyData = companyDoc.data();
            fetchedCompanyName = companyData?['companyName'];
            fetchedCompanyCode = companyData?['companyCode'];
          }
        }

        user = AdminUser.fromMap({
          ...userData,
          'companyName': fetchedCompanyName,
          'companyCode': fetchedCompanyCode,
        }, uid);
      } else if (role == 'driver') {
        user = DriverUser.fromMap(userData, uid);
      } else {
        user = UserModel.fromMap(userData, uid);
      }

      setState(() {
        currentUser = user;
        companyName = fetchedCompanyName;
        companyCode = fetchedCompanyCode;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  String _getRoleName(String? role) {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'driver':
        return 'Driver';
      default:
        return 'User';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("User data not found")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        selectedItemColor: Colors.grey,
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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const VehicleTrackingPage()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              );
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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

            // 👤 Profile Card
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 0),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundImage: currentUser!.profilePic != null
                          ? NetworkImage(currentUser!.profilePic!)
                          : const AssetImage('assets/images/profile.png')
                              as ImageProvider,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUser?.name ?? 'Loading...',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _getRoleName(currentUser?.role),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ℹ️ Info Card
            Card(
              margin: const EdgeInsets.symmetric(vertical: 12),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              elevation: 3,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 22, horizontal: 24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(
                        icon: Icons.email,
                        title: 'Email Address',
                        value: currentUser!.email,
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.phone,
                        title: 'Phone Number',
                        value: currentUser!.phone ?? 'Not provided',
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.calendar_today,
                        title: 'Membership Date',
                        value: currentUser!.createdAt != null
                            ? 'Joined: ${DateFormat.yMMMMd().format(currentUser!.createdAt!)}'
                            : 'Join date not available',
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.person_outline,
                        title: 'Account Type',
                        value: currentUser != null
                            ? (currentUser!.role == 'admin'
                                ? 'Administrator'
                                : currentUser!.role == 'driver'
                                    ? 'Driver'
                                    : 'User')
                            : 'Unknown',
                      ),
                      if (currentUser!.role == 'admin') ...[
                        const SizedBox(height: 12),
                        const Divider(color: Colors.grey),
                        const SizedBox(height: 12),
                        if (currentUser!.role == 'admin') ...[
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.business,
                            title: 'Company Name',
                            value: companyName ?? 'Loading...',
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.code,
                            title: 'Company Code',
                            value: companyCode ?? 'Loading...',
                          ),
                        ]
                      ]
                    ]),
              ),
            ),

            const SizedBox(height: 24),

            // 🔘 Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;

                      if (user != null) {
                        try {
                          final userDoc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .get();

                          final role = userDoc.data()?['role'];

                          // Cancel the right notification listener
                          if (role == 'admin') {
                            await AdminHomePage.cancelNotificationListener();
                          } else if (role == 'driver') {
                            await DriverHomePage.cancelNotificationListener();
                          } else {
                            print('Unknown role: $role');
                          }
                        } catch (e) {
                          print(
                              'Error while retrieving role or canceling listener: $e');
                        }
                      }

                      // Sign out
                      await FirebaseAuth.instance.signOut();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('You have been signed out successfully!'),
                          ),
                        );

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Color.fromARGB(255, 30, 30, 30),
                        fontWeight: FontWeight.w600,
                      ),
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
                      'Edit',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// 🔹 Info Row Widget
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
