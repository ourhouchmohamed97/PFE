class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String? profilePic;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.profilePic,
  });

  // Convert Firestore document to UserModel
  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      profilePic: data['profilePic'],
    );
  }

  // Convert UserModel to Map (for uploading to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'profilePic': profilePic,
    };
  }
}
