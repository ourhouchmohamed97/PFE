import 'package:bus_tracker/screens/d_login_Page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/constants.dart';
import 'package:fluttertoast/fluttertoast.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;

  const EmailVerificationPage({super.key, required this.email});

  @override
  _EmailVerificationPageState createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  String? errorMessage;
  bool isEmailSent = false;

  void sendVerificationEmail() async {
    try {
      User user = FirebaseAuth.instance.currentUser!;

      // Send verification email
      await user.sendEmailVerification();

      setState(() {
        isEmailSent = true;
        errorMessage = null;
      });

      Fluttertoast.showToast(
        msg: "Verification email sent to ${widget.email}",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      setState(() {
        errorMessage = "Failed to send verification email: $e";
      });
    }
  }

  void checkEmailVerification() async {
    try {
      User user = FirebaseAuth.instance.currentUser!;

      // Reload user to get the latest email verification status
      await user.reload();
      user = FirebaseAuth.instance.currentUser!;

      if (user.emailVerified) {
        // Update Firestore to mark email as verified
        await FirebaseFirestore.instance.collection('users').doc(widget.email).update({
          'emailVerified': true,
        });

        // Navigate to login page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        setState(() {
          errorMessage = "Email not verified. Please check your email and verify.";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error checking email verification: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(title: 'TRIPS'),
      body: _buildBody(context),
    );
  }

  Padding _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/darkCar.png',
            width: 100,
            height: 100,
            fit: BoxFit.contain,
          ),
          const Text(
            "Verify your email",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            isEmailSent
                ? "A verification link has been sent to ${widget.email}. Please check your inbox and click the link to verify your email."
                : "Click the button below to send a verification link to your email.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          if (errorMessage != null)
            Text(
              errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ElevatedButton(
            onPressed: checkEmailVerification,
            style: ElevatedButton.styleFrom(
              backgroundColor: blueColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 100),
            ),
            child: const Text(
              "CHECK VERIFICATION",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          TextButton(
            onPressed: sendVerificationEmail,
            child: const Text(
              "Resend Verification Email",
              style: TextStyle(
                color: Colors.blue,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}