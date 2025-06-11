import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationItem {
  final String docId;
  final String title;
  final String description;
  final DateTime timestamp;
  bool isRead;
  final IconData iconData;      // <-- Ici IconData au lieu de int
  final Color iconColor;
  final String? iconFontFamily;
  final String? iconFontPackage;
  final String? driverEmail;

  NotificationItem({
    required this.docId,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.isRead,
    required this.iconData,      
    required this.iconColor,
    this.iconFontFamily,
    this.iconFontPackage,
    this.driverEmail,
  });

  factory NotificationItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Construire l'IconData à partir des données Firestore
    IconData icon = IconData(
      data['iconData'] ?? Icons.notifications.codePoint,
      fontFamily: data['iconFontFamily'] ?? Icons.notifications.fontFamily,
      fontPackage: data['iconFontPackage'],
    );

    return NotificationItem(
      docId: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      iconData: icon,
      iconColor: Color(data['iconColor'] ?? 0xFF000000),
      iconFontFamily: data['iconFontFamily'],
      iconFontPackage: data['iconFontPackage'],
      driverEmail: data['driverEmail'],
    );
  }
}
