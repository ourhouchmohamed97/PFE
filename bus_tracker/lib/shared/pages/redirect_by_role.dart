import 'package:bus_tracker/shared/pages/b_welcome_Page.dart';
import 'package:bus_tracker/shared/pages/d_login_Page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_tracker/admin/screens/admin_home.dart';
import 'package:bus_tracker/driver/driver_home.dart';
import 'package:bus_tracker/driver/permission_waiting.dart';


class RedirectByRolePage extends StatefulWidget {
  const RedirectByRolePage({super.key});

  @override
  State<RedirectByRolePage> createState() => _RedirectByRolePageState();
}

class _RedirectByRolePageState extends State<RedirectByRolePage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleRedirection();
    });
  }

  Future<void> _handleRedirection() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Not logged in → go to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    if (!user.emailVerified) {
      await user.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify your email.')),
      );
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Welcome()),
      );
      return;
    }

    final role = userDoc.get('role');
    final status = userDoc.get('status') ?? 'pending';

    if (!mounted) return;

    if (role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomePage()),
      );
    } else if (role == 'driver') {
      if (status == 'approved') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DriverHomePage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DriverWaitingForPermissionPage()),
        );
      }
    } else {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
