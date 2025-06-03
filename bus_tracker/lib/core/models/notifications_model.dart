import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationItem {
  final String docId;
  final String title;
  final String description;
  final DateTime timestamp;
  bool isRead;
  final int iconData;
  final Color iconColor;
  final String? iconFontFamily;
  final String? iconFontPackage;
  final String? driverEmail;  // <-- add this field

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
    this.driverEmail,   // <-- add to constructor
  });

  factory NotificationItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return NotificationItem(
      docId: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      iconData: data['iconData'] ?? 0,
      iconColor: Color(data['iconColor'] ?? 0xFF000000),
      iconFontFamily: data['iconFontFamily'],
      iconFontPackage: data['iconFontPackage'],
      driverEmail: data['driverEmail'],  // <-- extract here
    );
  }
}