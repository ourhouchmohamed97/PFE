import 'package:cloud_firestore/cloud_firestore.dart';

class Vehicle {
  final String vid;
  final String ownerId;
  final String brand;
  final String model;
  final String type;
  final int year;
  final String matricule;
  final List<String> photosURL;
  final DateTime createdAt;
  final bool status; 
  Vehicle({
    required this.vid,
    required this.ownerId,
    required this.brand,
    required this.model,
    required this.type,
    required this.year,
    required this.matricule,
    this.photosURL = const [],
    required this.createdAt,
    this.status = false, 
  });

  factory Vehicle.fromMap(String id, Map<String, dynamic> map) {
    return Vehicle(
      vid: id,
      ownerId: map['ownerId'] ?? '',
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      type: map['type'] ?? '',
      year: map['year'] is int ? map['year'] : int.tryParse(map['year'].toString()) ?? 0,
      matricule: map['matricule'] ?? '',
      photosURL: List<String>.from(map['photos'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] ?? false, 
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'brand': brand,
      'model': model,
      'type': type,
      'year': year,
      'matricule': matricule,
      'photos': photosURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status, 
    };
  }
}
