import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bantay_eskwela/core/validators/input_validators.dart';

/// Consent form model for parent consent tracking.
class ConsentModel {
  final String id;
  final String eventId;
  final String eventTitle;
  final String fileUrl; // Firebase Storage URL
  final String fileName;
  final String uploadedBy; // Principal's user ID
  final DateTime deadline;
  final bool isActive;
  final DateTime createdAt;

  const ConsentModel({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.fileUrl,
    required this.fileName,
    required this.uploadedBy,
    required this.deadline,
    this.isActive = true,
    required this.createdAt,
  });

  factory ConsentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ConsentModel(
      id: doc.id,
      eventId: data['eventId'] as String? ?? '',
      eventTitle: InputValidators.sanitize(data['eventTitle'] as String? ?? ''),
      fileUrl: data['fileUrl'] as String? ?? '',
      fileName: InputValidators.sanitize(data['fileName'] as String? ?? ''),
      uploadedBy: data['uploadedBy'] as String? ?? '',
      deadline: (data['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'eventTitle': InputValidators.sanitize(eventTitle),
      'fileUrl': fileUrl,
      'fileName': InputValidators.sanitize(fileName),
      'uploadedBy': uploadedBy,
      'deadline': Timestamp.fromDate(deadline),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
