import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bantay_eskwela/core/enums/user_role.dart';
import 'package:bantay_eskwela/core/validators/input_validators.dart';

/// User model for BantayEskwela.
/// Maps directly to Firestore 'users' collection documents.
class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String photoUrl;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    this.photoUrl = '',
    required this.role,
    this.isActive = true,
    required this.createdAt,
    this.lastLoginAt,
  });

  /// Create UserModel from Firestore document with validation
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Validate required fields exist
    if (!data.containsKey('email') ||
        !data.containsKey('fullName') ||
        !data.containsKey('role')) {
      throw FormatException('Invalid user document: missing required fields');
    }

    return UserModel(
      uid: doc.id,
      email: InputValidators.sanitize(data['email'] as String? ?? ''),
      fullName: InputValidators.sanitize(data['fullName'] as String? ?? ''),
      photoUrl: data['photoUrl'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String? ?? ''),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore document map
  Map<String, dynamic> toFirestore() {
    return {
      'email': InputValidators.sanitize(email),
      'fullName': InputValidators.sanitize(fullName),
      'photoUrl': photoUrl,
      'role': role.value,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt':
          lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? fullName,
    String? photoUrl,
    UserRole? role,
    bool? isActive,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      fullName: fullName ?? this.fullName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
