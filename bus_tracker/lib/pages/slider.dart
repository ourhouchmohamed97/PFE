// import 'package:bus_tracker/pages/constants.dart';
// import 'package:bus_tracker/pages/login.dart';
// import 'package:flutter/material.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// class FeatureCard {
//   final String title;
//   final String description;
//   final IconData icon;
//   final String imagePath;

//   FeatureCard({
//     required this.title,
//     required this.description,
//     required this.icon,
//     required this.imagePath,
//   });
// }

// class CarouselPage extends StatefulWidget {
//   const CarouselPage({super.key});

//   @override
//   State<CarouselPage> createState() => _CarouselPageState();
// }

// class _CarouselPageState extends State<CarouselPage> {
//   int _currentIndex = 0;

//   final List<FeatureCard> appFeatures = [
//     FeatureCard(
//       title: "Real-Time Tracking",
//       description: "Track your rented vehicle's location live on the map",
//       icon: Icons.location_on,
//       imagePath: 'assets/images/track.jpeg',
//     ),
//     FeatureCard(
//       title: "Vehicle Browsing",
//       description: "Browse available cars with filters for price and type",
//       icon: Icons.directions_car,
//       imagePath: 'assets/images/car.jpeg',
//     ),
//     FeatureCard(
//       title: "Secure Payments",
//       description: "Complete rentals with our encrypted payment system",
//       icon: Icons.payment,
//       imagePath: 'assets/images/payment.jpeg',
//     ),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: const CustomAppBar(
//         title: 'CarTrack',
//       ),
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.center, 
//         crossAxisAlignment: CrossAxisAlignment.center, 
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const SizedBox(height: 40),
//           // Wrap carousel in a fixed height container
//           SizedBox(
//             height: 600, // Adjust as needed
//             child: Column(
//               mainAxisAlignment:
//                   MainAxisAlignment.center, // Center within container
//               children: [
//                 // Carousel
//                 CarouselSlider.builder(
//                   itemCount: appFeatures.length,
//                   itemBuilder: (context, index, realIndex) {
//                     FeatureCard feature = appFeatures[index];
//                     return Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 8),
//                       child: Card(
//                         elevation: 4,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         child: Container(
//                           padding: const EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             gradient: const LinearGradient(
//                               begin: Alignment.topLeft,
//                               end: Alignment.bottomRight,
//                               colors: [
//                                 Colors.white,
//                                 Color.fromRGBO(240, 248, 255, 1),
//                               ],
//                             ),
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             mainAxisAlignment: MainAxisAlignment
//                                 .center, 
//                             children: [
//                               Row(
//                                 children: [
//                                   Container(
//                                     padding: const EdgeInsets.all(8),
//                                     decoration: BoxDecoration(
//                                       color: Colors.blue.withOpacity(0.1),
//                                       borderRadius: BorderRadius.circular(10),
//                                     ),
//                                     child: Icon(
//                                       feature.icon,
//                                       color: Colors.blue,
//                                       size: 24,
//                                     ),
//                                   ),
//                                   const SizedBox(width: 12),
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           feature.title,
//                                           style: const TextStyle(
//                                             fontSize: 16,
//                                             fontWeight: FontWeight.bold,
//                                             color: Colors.black87,
//                                           ),
//                                         ),
//                                         const SizedBox(height: 4),
//                                         Text(
//                                           feature.description,
//                                           style: const TextStyle(
//                                             color: Colors.grey,
//                                             fontSize: 12,
//                                             height: 1.3,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 12),
//                               ClipRRect(
//                                 borderRadius: BorderRadius.circular(12),
//                                 child: Image.asset(
//                                   feature.imagePath,
//                                   height: 90,
//                                   width: double.infinity,
//                                   fit: BoxFit.cover,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                   options: CarouselOptions(
//                     height: 420, // Fixed height for cards
//                     autoPlay: true,
//                     enlargeCenterPage: true,
//                     viewportFraction: 0.9,
//                     onPageChanged: (index, reason) {
//                       setState(() => _currentIndex = index);
//                     },
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 SmoothPageIndicator(
//                   controller: PageController(initialPage: _currentIndex),
//                   count: appFeatures.length,
//                   effect: ExpandingDotsEffect(
//                     dotHeight: 8,
//                     dotWidth: 8,
//                     spacing: 6,
//                     radius: 12,
//                     expansionFactor: 3,
//                     dotColor: Colors.grey.shade400,
//                     activeDotColor: Colors.blue,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 20),

//           // Button stays below the carousel
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 32),
//             child: ElevatedButton(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => const LoginPage()),
//                 );
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue,
//                 padding: const EdgeInsets.symmetric(vertical: 14),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 minimumSize: const Size(double.infinity, 45),
//               ),
//               child: const Text(
//                 "Get Started",
//                 style: TextStyle(fontSize: 15),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
