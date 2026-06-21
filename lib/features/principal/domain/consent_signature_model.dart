import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bantay_eskwela/core/validators/input_validators.dart';

/// An immutable record of a parent digitally signing a consent form
/// for one of their children. Includes the captured signature image URL.
class ConsentSignature {
  final String id;
  final String consentId;
  final String eventTitle;
  final String studentId;
  final String studentName;
  final String parentId;
  final String parentName;
  final String signatureUrl;
  final DateTime signedAt;

  const ConsentSignature({
    required this.id,
    required this.consentId,
    required this.eventTitle,
    required this.studentId,
    required this.studentName,
    required this.parentId,
    required this.parentName,
    required this.signatureUrl,
    required this.signedAt,
  });

  factory ConsentSignature.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ConsentSignature(
      id: doc.id,
      consentId: data['consentId'] as String? ?? '',
      eventTitle: InputValidators.sanitize(data['eventTitle'] as String? ?? ''),
      studentId: data['studentId'] as String? ?? '',
      studentName:
          InputValidators.sanitize(data['studentName'] as String? ?? ''),
      parentId: data['parentId'] as String? ?? '',
      parentName:
          InputValidators.sanitize(data['parentName'] as String? ?? 'Parent'),
      signatureUrl: data['signatureUrl'] as String? ?? '',
      signedAt: (data['signedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
