import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationItem {
  final String docId;
  final String title;
  final String description;
  final DateTime timestamp;
  bool isRead;
  final IconData iconData;
  final Color iconColor;
  final String? iconFontFamily;
  final String? iconFontPackage;
  final String? driverUid;  // Changed from driverEmail

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
    this.driverUid,
  });

  factory NotificationItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final int codePoint = data['iconCodePoint'] ?? Icons.notifications.codePoint;
    final String? fontFamily = data['iconFontFamily'] ?? Icons.notifications.fontFamily;
    final String? fontPackage = data['iconFontPackage'];

    return NotificationItem(
      docId: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      iconData: IconData(codePoint, fontFamily: fontFamily, fontPackage: fontPackage),
      iconColor: Color(data['iconColor'] ?? 0xFF000000),
      iconFontFamily: fontFamily,
      iconFontPackage: fontPackage,
      driverUid: data['driverUid'],  // Updated here
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'iconCodePoint': iconData.codePoint,
      'iconFontFamily': iconFontFamily,
      'iconFontPackage': iconFontPackage,
      'iconColor': iconColor.toARGB32(),  
      'driverUid': driverUid,        
    };
  }
}

