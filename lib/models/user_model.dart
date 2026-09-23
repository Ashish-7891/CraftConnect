import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String role; // 'ARTISAN' or 'CUSTOMER'
  final String? profileImage;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.profileImage,
    this.createdAt,
  });

  bool get isArtisan => role.toUpperCase() == 'ARTISAN';
  bool get isCustomer => role.toUpperCase() == 'CUSTOMER';

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      role: (data['role'] ?? 'CUSTOMER').toString().toUpperCase(),
      profileImage: data['profileImage'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['createdAt'].toString()))
          : null,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      role: (data['role'] ?? 'CUSTOMER').toString().toUpperCase(),
      profileImage: data['profileImage'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['createdAt'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
      'role': role.toUpperCase(),
      if (profileImage != null) 'profileImage': profileImage,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? name,
    String? phone,
    String? profileImage,
    String? role,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt,
    );
  }
}
