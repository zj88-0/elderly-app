// lib/models/user_model.dart
// FULL FILE — patched for Firebase compatibility.
// Changes from original:
//   1. password field defaults to '' (Firebase Auth manages it, not stored in Firestore)
//   2. Added toFirestore() method — same as toJson() but without password
//   3. fromJson() handles missing password gracefully with ?? ''

enum UserRole { elderly, caregiver }

class UserModel {
  final String id;
  String name;
  String email;
  String password; // local only — never written to Firestore; '' when from Firebase
  UserRole role;
  String? groupId;
  List<String> groupIds;
  String? phoneNumber;
  DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.groupId,
    List<String>? groupIds,
    this.phoneNumber,
    DateTime? createdAt,
  })  : groupIds = groupIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  // ── toJson: includes password — used for LOCAL SharedPreferences only ──
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'password': password,
    'role': role.name,
    'groupId': groupId,
    'groupIds': groupIds,
    'phoneNumber': phoneNumber,
    'createdAt': createdAt.toIso8601String(),
  };

  // ── toFirestore: NO password — used when writing to Firestore ──────────
  Map<String, dynamic> toFirestore() => {
    'name': name,
    'email': email,
    'role': role.name,
    'groupId': groupId,
    'groupIds': groupIds,
    'phoneNumber': phoneNumber,
    'createdAt': createdAt.toIso8601String(),
  };

  // ── fromJson: password defaults to '' when missing (Firestore docs) ────
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    password: (json['password'] as String?) ?? '',
    role: UserRole.values.firstWhere((r) => r.name == json['role']),
    groupId: json['groupId'] as String?,
    groupIds: List<String>.from(json['groupIds'] ?? []),
    phoneNumber: json['phoneNumber'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  UserModel copyWith({
    String? name,
    String? email,
    String? password,
    UserRole? role,
    String? groupId,
    List<String>? groupIds,
    String? phoneNumber,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        password: password ?? this.password,
        role: role ?? this.role,
        groupId: groupId ?? this.groupId,
        groupIds: groupIds ?? this.groupIds,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        createdAt: createdAt,
      );
}