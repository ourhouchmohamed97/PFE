class Company {
  final String id;
  final String name;
  final String code;

  Company({
    required this.id,
    required this.name,
    required this.code,
  });

  factory Company.fromMap(Map<String, dynamic> map, String id) {
    return Company(
      id: id,
      name: map['name'] ?? '',
      code: map['code'] ?? '',
    );
  }
}