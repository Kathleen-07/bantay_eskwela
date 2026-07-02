import 'package:cloud_firestore/cloud_firestore.dart';

/// A "pending scan" written by the ESP32 gate scanner (GM65 QR reader).
/// The scanner writes the raw QR token (qrData, e.g. "BE-...") when
/// available; studentId is kept as a legacy fallback for older test data.
class GateScan {
  final String id;
  final String studentId;
  final String qrData;
  final DateTime scannedAt;

  const GateScan({
    required this.id,
    required this.studentId,
    required this.qrData,
    required this.scannedAt,
  });

  /// Prefer the QR token; fall back to studentId for legacy/manual test docs.
  String get lookupValue => qrData.isNotEmpty ? qrData : studentId;

  bool get isQrToken => qrData.isNotEmpty;

  factory GateScan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return GateScan(
      id: doc.id,
      studentId: data['studentId'] as String? ?? '',
      qrData: data['qrData'] as String? ?? '',
      scannedAt: (data['scannedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
