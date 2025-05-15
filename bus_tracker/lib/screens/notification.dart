import 'package:flutter/material.dart';
import 'package:bus_tracker/screens/home.dart';
import 'package:bus_tracker/screens/setting.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final filteredNotifications = _filter == 'All'
        ? _notifications
        : _notifications
            .where((n) => _filter == 'Unread' ? !n.isRead : n.isRead)
            .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔷 Filter + Mark All as Read
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filter,
                      icon: const Icon(Icons.arrow_drop_down),
                      style: const TextStyle(color: Colors.black),
                      items: const [
                        DropdownMenuItem(
                          value: 'All',
                          child: Text('All'),
                        ),
                        DropdownMenuItem(
                          value: 'Unread',
                          child: Text('Unread'),
                        ),
                        DropdownMenuItem(
                          value: 'Read',
                          child: Text('Read'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filter = value!;
                        });
                      },
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      for (var n in _notifications) {
                        n.isRead = true;
                      }
                    });
                  },
                  child: const Text(
                    'Mark all as read',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(
              color: Colors.grey,
              thickness: 1,
            ),
            // 🔔 Notifications List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredNotifications.length,
              itemBuilder: (context, index) {
                final notification = filteredNotifications[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      notification.isRead = true;
                    });
                  },
                  child: Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: notification.iconColor,
                              child: Icon(notification.iconData,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notification.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notification.timestamp,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    notification.description,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!notification.isRead)
                        const Positioned(
                          top: 8,
                          right: 8,
                          child:
                              Icon(Icons.circle, color: Colors.blue, size: 10),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
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
                MaterialPageRoute(builder: (_) => const ActiveVehiclesPage()),
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
    );
  }
}

// 🔰 Notification Model
class NotificationItem {
  final IconData iconData;
  final Color iconColor;
  final String title;
  final String timestamp;
  final String description;
  bool isRead;

  NotificationItem({
    required this.iconData,
    required this.iconColor,
    required this.title,
    required this.timestamp,
    required this.description,
    this.isRead = false,
  });
}

// 📄 Sample Notification Data
final List<NotificationItem> _notifications = [
  NotificationItem(
    iconData: Icons.check_circle,
    iconColor: Colors.green,
    title: 'Vehicle Returned',
    timestamp: 'Just now',
    description: 'Vehicle Plate ABC-123 successfully returned.',
  ),
  NotificationItem(
    iconData: Icons.info,
    iconColor: Colors.blue,
    title: 'New Booking Confirmed',
    timestamp: '5 minutes ago',
    description:
        'Your booking for Vehicle XYZ-456 on May 1, 2025 is confirmed.',
  ),
  NotificationItem(
    iconData: Icons.warning,
    iconColor: Colors.orange,
    title: 'Payment Due Soon',
    timestamp: '2 hours ago',
    description: 'Your rental payment for Vehicle LMN-789 is due tomorrow.',
  ),
  NotificationItem(
    iconData: Icons.check_circle,
    iconColor: Colors.green,
    title: 'Profile Updated',
    timestamp: 'April 14, 2025',
    description: 'Your profile information has been successfully updated.',
  ),
  NotificationItem(
    iconData: Icons.info,
    iconColor: Colors.blue,
    title: 'New Feature Available',
    timestamp: 'April 10, 2025',
    description: 'Check out the new car search filter options!',
  ),
];
