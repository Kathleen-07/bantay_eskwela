import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bantay_eskwela/features/principal/domain/student_model.dart';
import 'package:bantay_eskwela/features/parent/data/parent_repository.dart'
    show AttendanceRecord;
import 'package:bantay_eskwela/features/guard/domain/gate_scan_model.dart';

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
  Stream<GateScan?> watchPendingScan() {
    return _firestore.collection('gate_scans').snapshots().map((snap) {
      if (snap.docs.isEmpty) return null;
      final scans = snap.docs.map((d) => GateScan.fromFirestore(d)).toList()
        ..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
      final latest = scans.first;
      final cutoff = DateTime.now().subtract(const Duration(minutes: 2));
      if (latest.scannedAt.isBefore(cutoff)) return null;
      return latest;
    });
  }

  /// Look up a student by QR token first (qrData), falling back to
  /// studentId for legacy/manual test scans.
  Future<StudentModel?> findStudentForScan(GateScan scan) async {
    if (scan.isQrToken) {
      final byQr = await _firestore
          .collection('students')
          .where('qrData', isEqualTo: scan.qrData)
          .limit(1)
          .get();
      if (byQr.docs.isNotEmpty) {
        return StudentModel.fromFirestore(byQr.docs.first);
      }
    }
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

  /// Write the final attendance record, then clear the staging scan doc.
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

  /// Dismiss a scan without recording attendance (duplicate / not found).
  Future<void> dismissScan(String scanId) async {
    await _firestore.collection('gate_scans').doc(scanId).delete();
  }

  /// Live map of studentId -> StudentModel for photo / grade / section
  /// lookups in the log (live lookup, not a stale snapshot).
  Stream<Map<String, StudentModel>> getStudentsByIdStream() {
    return _firestore.collection('students').snapshots().map((snap) {
      final map = <String, StudentModel>{};
      for (final d in snap.docs) {
        final s = StudentModel.fromFirestore(d);
        map[s.studentId] = s;
      }
      return map;
    });
  }

  /// All of today's attendance records (for the log + duplicate checks).
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
