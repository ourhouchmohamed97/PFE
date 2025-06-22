import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Terms & Conditions', style: GoogleFonts.poppins()),
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
            'By using the Car Tracker app, you agree to the following terms:\n\n'
            '- You must provide accurate information during account registration.\n'
            '- You are responsible for the confidentiality of your account credentials.\n'
            '- You agree not to misuse the app or its services.\n'
            '- The app provides car tracking and rental assistance but is not liable for any issues between renters and agencies.\n\n'
            'We reserve the right to suspend access if terms are violated.\n\n'
            'Thank you for using Car Tracker.',
            style: GoogleFonts.poppins(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
