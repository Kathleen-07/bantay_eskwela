import 'package:cloud_firestore/cloud_firestore.dart';

/// A "pending scan" written by the ESP32-CAM gate scanner.
/// The Guard tablet app reacts to this, looks up the student,
/// and the guard confirms Time In / Time Out.
class GateScan {
  final String id;
  final String studentId;
  final DateTime scannedAt;

  const GateScan({
    required this.id,
    required this.studentId,
    required this.scannedAt,
  });

  factory GateScan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return GateScan(
      id: doc.id,
      studentId: data['studentId'] as String? ?? '',
      scannedAt: (data['scannedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
