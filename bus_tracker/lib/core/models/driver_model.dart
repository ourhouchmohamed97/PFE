import 'package:bus_tracker/core/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverUser extends UserModel {
  final String adminEmail;
  final bool isActive;

  DriverUser({
    required super.uid,
    required super.name,
    required super.email,
    required super.role,
    super.phone,
    super.profilePic,
    super.createdAt,
    required this.adminEmail,
    required this.isActive,
  });

  factory DriverUser.fromMap(Map<String, dynamic> map, String uid) {
    return DriverUser(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'driver',
      phone: map['phone'],
      profilePic: map['profilePic'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      adminEmail: map['adminEmail'] ?? '',
      isActive: map['isActive'] ?? false,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final baseMap = super.toMap();
    return {
      ...baseMap,
      'adminEmail': adminEmail,
      'isActive': isActive,
    };
  }
}
