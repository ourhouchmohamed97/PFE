import 'package:bus_tracker/core/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUser extends UserModel {
  final String companyName;
  final String companyType;

  AdminUser({
    required super.uid,
    required super.name,
    required super.email,
    required super.role,
    super.phone,
    super.profilePic,
    super.createdAt,
    required this.companyName,
    required this.companyType,
  });

  factory AdminUser.fromMap(Map<String, dynamic> map, String uid) {
    return AdminUser(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'admin',
      phone: map['phone'],
      profilePic: map['profilePic'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      companyName: map['companyName'] ?? '',
      companyType: map['companyType'] ?? '',
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final baseMap = super.toMap();
    return {
      ...baseMap,
      'companyName': companyName,
      'companyType': companyType,
    };
  }
}
