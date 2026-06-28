import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bantay_eskwela/core/validators/input_validators.dart';

enum ViolationSeverity { minor, major, severe }

extension ViolationSeverityX on ViolationSeverity {
  String get label {
    switch (this) {
      case ViolationSeverity.minor:
        return 'Minor';
      case ViolationSeverity.major:
        return 'Major';
      case ViolationSeverity.severe:
        return 'Severe';
    }
  }

  static ViolationSeverity fromString(String s) {
    switch (s.toLowerCase()) {
      case 'major':
        return ViolationSeverity.major;
      case 'severe':
        return ViolationSeverity.severe;
      default:
        return ViolationSeverity.minor;
    }
  }
}

/// A student disciplinary record, created by Guidance.
/// Stores [parentId] so the student's parent can read it (enforced by rules).
class ViolationModel {
  final String id;
  final String studentId;
  final String studentName;
  final String gradeLevel;
  final String section;
  final String parentId; // required for parent-read security rule
  final String type;
  final String description;
  final ViolationSeverity severity;
  final String actionTaken; // e.g. 'Pending', 'Verbal Warning', 'Suspension'
  final DateTime dateOfIncident;
  final String recordedBy;
  final String recordedByName;
  final DateTime createdAt;

  const ViolationModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.gradeLevel,
    required this.section,
    required this.parentId,
    required this.type,
    required this.description,
    required this.severity,
    this.actionTaken = 'Pending',
    required this.dateOfIncident,
    required this.recordedBy,
    required this.recordedByName,
    required this.createdAt,
  });

  factory ViolationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ViolationModel(
      id: doc.id,
      studentId: data['studentId'] as String? ?? '',
      studentName:
          InputValidators.sanitize(data['studentName'] as String? ?? ''),
      gradeLevel: data['gradeLevel'] as String? ?? '',
      section: data['section'] as String? ?? '',
      parentId: data['parentId'] as String? ?? '',
      type: InputValidators.sanitize(data['type'] as String? ?? ''),
      description:
          InputValidators.sanitize(data['description'] as String? ?? ''),
      severity: ViolationSeverityX.fromString(
          data['severity'] as String? ?? 'minor'),
      actionTaken: InputValidators.sanitize(
          data['actionTaken'] as String? ?? 'Pending'),
      dateOfIncident:
          (data['dateOfIncident'] as Timestamp?)?.toDate() ?? DateTime.now(),
      recordedBy: data['recordedBy'] as String? ?? '',
      recordedByName:
          InputValidators.sanitize(data['recordedByName'] as String? ?? ''),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'studentId': studentId,
        'studentName': studentName,
        'gradeLevel': gradeLevel,
        'section': section,
        'parentId': parentId,
        'type': type,
        'description': description,
        'severity': severity.label,
        'actionTaken': actionTaken,
        'dateOfIncident': Timestamp.fromDate(dateOfIncident),
        'recordedBy': recordedBy,
        'recordedByName': recordedByName,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
