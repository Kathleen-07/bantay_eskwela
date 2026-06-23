import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bantay_eskwela/features/principal/domain/student_model.dart';
import 'package:bantay_eskwela/features/parent/data/parent_repository.dart'
    show AttendanceRecord;
import 'package:bantay_eskwela/features/guard/domain/gate_scan_model.dart';

/// Repository for the Guard role.
/// Reacts to scans written by the ESP32-CAM gate scanner, looks up the
/// student, and records the final attendance entry once the guard confirms.
class GuardRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  GuardRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _uid {
    final u = _auth.currentUser;
    if (u == null) throw Exception('Not authenticated');
    return u.uid;
  }

  /// The most recent unprocessed scan, or null if none / too old.
  /// A scan older than 2 minutes is treated as expired (ignored).
  Stream<GateScan?> watchPendingScan() {
    return _firestore.collection('gate_scans').snapshots().map((snap) {
      if (snap.docs.isEmpty) return null;
      final scans =
          snap.docs.map((d) => GateScan.fromFirestore(d)).toList()
            ..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
      final latest = scans.first;
      final cutoff = DateTime.now().subtract(const Duration(minutes: 2));
      if (latest.scannedAt.isBefore(cutoff)) return null;
      return latest;
    });
  }

  /// Look up a student from a scan. Prefers matching the QR token
  /// (`qrData`), and falls back to `studentId` for legacy test docs.
  Future<StudentModel?> findStudentForScan(GateScan scan) async {
    // 1. Try matching the QR token against students' qrData.
    if (scan.qrData.isNotEmpty) {
      final byQr = await _firestore
          .collection('students')
          .where('qrData', isEqualTo: scan.qrData)
          .limit(1)
          .get();
      if (byQr.docs.isNotEmpty) {
        return StudentModel.fromFirestore(byQr.docs.first);
      }
    }
    // 2. Fallback: match an explicit studentId (legacy/manual test docs).
    if (scan.studentId.isNotEmpty) {
      final byId = await _firestore
          .collection('students')
          .where('studentId', isEqualTo: scan.studentId)
          .limit(1)
          .get();
      if (byId.docs.isNotEmpty) {
        return StudentModel.fromFirestore(byId.docs.first);
      }
    }
    return null;
  }

  /// Confirm the scan: write the final attendance record, then clear
  /// the staging scan doc.
  Future<void> confirmAttendance({
    required GateScan scan,
    required StudentModel student,
    required String type, // 'Time In' or 'Time Out'
  }) async {
    await _firestore.collection('attendance').doc().set({
      'studentId': student.studentId,
      'studentName': student.fullName,
      'parentId': student.parentId,
      'type': type,
      'timestamp': Timestamp.now(),
      'recordedBy': _uid,
    });
    await _firestore.collection('gate_scans').doc(scan.id).delete();
  }

  /// Dismiss a scan without recording attendance (e.g. wrong/duplicate scan).
  Future<void> dismissScan(String scanId) async {
    await _firestore.collection('gate_scans').doc(scanId).delete();
  }

  /// All of today's attendance records (for the on-screen log).
  Stream<List<AttendanceRecord>> getTodayLogStream() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    return _firestore.collection('attendance').snapshots().map((snap) {
      final list = snap.docs
          .map((d) => AttendanceRecord.fromFirestore(d))
          .where((a) => a.timestamp.isAfter(startOfToday))
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }
}
