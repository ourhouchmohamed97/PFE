import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Privacy Policy', style: GoogleFonts.poppins()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Text(
            'We value your privacy.\n\n'
            'This app collects limited personal data, including your email and phone number, to provide account management and improve your experience.\n\n'
            'We do not sell your data to third parties.\n\n'
            'All data is stored securely using Firebase services. You have the right to access or delete your personal information anytime.\n\n'
            'By using this app, you agree to this Privacy Policy.',
            style: GoogleFonts.poppins(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
