import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bantay_eskwela/core/validators/input_validators.dart';

/// Student model for BantayEskwela.
/// Represents a registered student with QR code data and photo.
class StudentModel {
  final String id;
  final String studentId;
  final String fullName;
  final String section;
  final String gradeLevel;
  final String parentId;
  final String parentPhone;
  final String qrData;
  final String photoUrl; // Student photo stored in Firebase Storage
  final bool isActive;
  final DateTime createdAt;

  const StudentModel({
    required this.id,
    required this.studentId,
    required this.fullName,
    required this.section,
    required this.gradeLevel,
    required this.parentId,
    required this.parentPhone,
    required this.qrData,
    this.photoUrl = '',
    this.isActive = true,
    required this.createdAt,
  });

  factory StudentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StudentModel(
      id: doc.id,
      studentId: InputValidators.sanitize(data['studentId'] as String? ?? ''),
      fullName: InputValidators.sanitize(data['fullName'] as String? ?? ''),
      section: InputValidators.sanitize(data['section'] as String? ?? ''),
      gradeLevel: InputValidators.sanitize(data['gradeLevel'] as String? ?? ''),
      parentId: data['parentId'] as String? ?? '',
      parentPhone: data['parentPhone'] as String? ?? '',
      qrData: data['qrData'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': InputValidators.sanitize(studentId),
      'fullName': InputValidators.sanitize(fullName),
      'section': InputValidators.sanitize(section),
      'gradeLevel': InputValidators.sanitize(gradeLevel),
      'parentId': parentId,
      'parentPhone': parentPhone,
      'qrData': qrData,
      'photoUrl': photoUrl,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
