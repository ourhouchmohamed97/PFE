class Vehicle {
  final String vid;
  final String companyId; // ✅ fixed typo
  final String brand;
  final String model;
  final String type;
  final int year;
  final String matricule;
  final DateTime createdAt;
  final List<String> photosURL;
  final String? assignedDriverId;
  final Map<String, dynamic>? location;

  Vehicle({
    required this.vid,
    required this.companyId,
    required this.brand,
    required this.model,
    required this.type,
    required this.year,
    required this.matricule,
    required this.createdAt,
    required this.photosURL,
    this.assignedDriverId,
    this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'vid': vid,
      'companyId': companyId, 
      'brand': brand,
      'model': model,
      'type': type,
      'year': year,
      'matricule': matricule,
      'createdAt': createdAt.toIso8601String(),
      'photosURL': photosURL,
      'assignedDriverId': assignedDriverId,
      'location': location,
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      vid: map['vid'],
      companyId: map['companyId'], // ✅ fixed here too
      brand: map['brand'],
      model: map['model'],
      type: map['type'],
      year: map['year'],
      matricule: map['matricule'],
      createdAt: DateTime.parse(map['createdAt']),
      photosURL: List<String>.from(map['photosURL']),
      assignedDriverId: map['assignedDriverId'],
      location: map['location'] != null
          ? Map<String, dynamic>.from(map['location'])
          : null,
    );
  }
}
