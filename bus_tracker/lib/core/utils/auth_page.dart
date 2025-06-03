import 'package:bus_tracker/admin/screens/admin_home.dart';
import 'package:bus_tracker/driver/driver_home.dart';
import 'package:bus_tracker/shared/pages/d_login_Page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  Future<Widget> _getHomeScreen(User user) async {
    if (!user.emailVerified) {
      return const LoginPage(); // Or a verify email page
    }

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        String role = userDoc.get('role');

        if (role == 'admin') {
          return const AdminHomePage();
        } else if (role == 'driver') {
          return const DriverHomePage();
        } else {
          return const LoginPage(); // Unknown role
        }
      } else {
        return const LoginPage(); // No user document found
      }
    } catch (e) {
      return const LoginPage(); // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            final user = snapshot.data!;
            return FutureBuilder<Widget>(
              future: _getHomeScreen(user),
              builder: (context, futureSnapshot) {
                if (futureSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return futureSnapshot.data!;
              },
            );
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}
