import 'package:cloud_firestore/cloud_firestore.dart';

/// A "pending scan" written by the ESP32-CAM gate scanner.
/// The Guard tablet app reacts to this, looks up the student by the QR
/// token, and the guard confirms Time In / Time Out.
///
/// The ESP32 writes the raw QR payload (a "BE-<uuid>" token) into the
/// `qrData` field. For backward compatibility with early test docs, a
/// plain `studentId` field is also accepted.
class GateScan {
  final String id;
  final String qrData; // the scanned QR token, e.g. "BE-xxxx..."
  final String studentId; // optional legacy/explicit id (test docs)
  final DateTime scannedAt;

  const GateScan({
    required this.id,
    required this.qrData,
    required this.studentId,
    required this.scannedAt,
  });

  /// The value to use when looking up the student.
  /// Prefers the QR token; falls back to studentId for legacy test docs.
  String get lookupValue => qrData.isNotEmpty ? qrData : studentId;

  /// Whether this scan carries a QR token (vs a legacy studentId).
  bool get isQrToken => qrData.isNotEmpty;

  factory GateScan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return GateScan(
      id: doc.id,
      qrData: data['qrData'] as String? ?? '',
      studentId: data['studentId'] as String? ?? '',
      scannedAt: (data['scannedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
