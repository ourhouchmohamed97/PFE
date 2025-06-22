import 'package:bus_tracker/admin/screens/subscrib_plan.dart';
import 'package:bus_tracker/core/widgets/constants.dart';
import 'package:bus_tracker/shared/pages/a_home_Page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class FeatureCard {
  final String title;
  final String description;
  final String imagePath;

  FeatureCard({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

class CarouselPage extends StatefulWidget {
  const CarouselPage({super.key});

  @override
  State<CarouselPage> createState() => _CarouselPageState();
}

class _CarouselPageState extends State<CarouselPage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<FeatureCard> appFeatures = [
    FeatureCard(
      title: "Welcome to Smiya D App",
      description:
          "Track and manage your activity effortlessly. Let us simplify your day with smart tools designed just for you.",
      imagePath: 'assets/images/welcome.png',
    ),
    FeatureCard(
      title: "Real-Time Tracking",
      description:
          "Stay informed with live updates and notifications—wherever you go, we’ve got your back.",
      imagePath: 'assets/images/tracking.png',
    ),
    FeatureCard(
      title: "Secure and Easy to Use",
      description:
          "Enjoy a seamless experience with strong security and intuitive design that puts you in control.",
      imagePath: 'assets/images/control.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  top: 40, right: 16), // Adjust `top` as needed
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Homepage()),
                    );
                  },
                  child: Text(
                    "Skip",
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: appFeatures.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  final feature = appFeatures[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          feature.imagePath,
                          height: 260,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          feature.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          feature.description,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.grey[700],
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            SmoothPageIndicator(
              controller: _pageController,
              count: appFeatures.length,
              effect: ExpandingDotsEffect(
                dotHeight: 10,
                dotWidth: 10,
                spacing: 6,
                radius: 12,
                expansionFactor: 3,
                dotColor: Colors.grey.shade300,
                activeDotColor: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ElevatedButton(
                onPressed: () {
                  if (_currentIndex == appFeatures.length - 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SubscriptionPlanPage()),
                    );
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: blueColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  minimumSize: const Size(double.infinity, 56),
                  elevation: 4,
                ),
                child: Text(
                  _currentIndex == appFeatures.length - 1
                      ? "Get Started"
                      : "Next",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white, // Ensures text is blue
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
