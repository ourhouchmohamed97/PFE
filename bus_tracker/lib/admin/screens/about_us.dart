import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('About Us', style: GoogleFonts.poppins()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Text(
            'Welcome to Car Tracker!\n\n'
            'We are a dedicated team passionate about helping car rental agencies efficiently track their fleet and provide the best service to their customers. '
            'Our mobile application enables real-time car tracking, seamless reservations, and smooth rental experiences.\n\n'
            'Thank you for choosing our service — we are committed to your satisfaction and safety.',
            style: GoogleFonts.poppins(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
