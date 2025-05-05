import 'package:bus_tracker/pages/constants.dart';
import 'package:flutter/material.dart';


class BusListPage extends StatelessWidget {
  const BusListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: blueColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black), // Arrow icon
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
        title: const Text(
          'List of Buses',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true, // Centers the title
        elevation: 0, // Removes shadow
      ),
      body: Stack(
        children: [
          // Background map image
          Image.asset(
            'assets/images/bg.png', // Replace with your map background image
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
          Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity, // Ensures the container takes up the full width
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true, // Limits height to its content
                    physics: const NeverScrollableScrollPhysics(), // Prevents internal scrolling
                    padding: const EdgeInsets.all(16),
                    itemCount: busData.length,
                    separatorBuilder: (context, index) => const Divider(
                      color: Colors.grey,
                      height: 1,
                      thickness: 1,
                    ),
                    itemBuilder: (context, index) {
                      final bus = busData[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Bus Icon and Line
                            Row(
                              children: [
                                Icon(Icons.directions_bus,
                                    color: bus['color'], size: 30),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    bus['line'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Passengers Count
                            Row(
                              children: [
                                Row(
                                  children: List.generate(
                                    3,
                                        (index) => Icon(
                                          Icons.person,
                                          size: 18,
                                          color: index < (bus['passengers'] / 25).floor()
                                              ? Colors.black87
                                              : Colors.grey,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${bus['passengers']}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Create Route Button at the bottom of the page
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to the route creation screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blueColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    fixedSize: Size(MediaQuery.of(context).size.width, 50),
                  ),
                  child: const Text(
                    'Create route',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const List<Map<String, dynamic>> busData = [
  {
    'line': 'Mdiq',
    'passengers': 94,
    'color': Colors.red,
  },
  {
    'line': 'Tetouan',
    'passengers': 82,
    'color': Colors.green,
  },
  {
    'line': 'Fnideq',
    'passengers': 60,
    'color': Colors.purple,
  },
  {
    'line': 'Martil',
    'passengers': 25,
    'color': Colors.red,
  },
];

