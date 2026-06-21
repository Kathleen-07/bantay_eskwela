import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bantay_eskwela/core/constants/app_constants.dart';
import 'package:bantay_eskwela/core/validators/input_validators.dart';
import 'package:bantay_eskwela/features/principal/domain/student_model.dart';
import 'package:bantay_eskwela/features/principal/domain/announcement_model.dart';
import 'package:bantay_eskwela/features/principal/domain/event_model.dart';
import 'package:bantay_eskwela/features/principal/domain/consent_model.dart';
import 'package:bantay_eskwela/features/principal/domain/consent_signature_model.dart';

/// A single attendance record (time-in / time-out) for a student.
class AttendanceRecord {
  final String id;
  final String studentId;
  final String studentName;
  final String parentId;
  final String type; // 'Time In' or 'Time Out'
  final DateTime timestamp;

  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.parentId,
    required this.type,
    required this.timestamp,
  });

  factory AttendanceRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceRecord(
      id: doc.id,
      studentId: data['studentId'] as String? ?? '',
      studentName: data['studentName'] as String? ?? '',
      parentId: data['parentId'] as String? ?? '',
      type: data['type'] as String? ?? 'Time In',
      timestamp:
          (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Repository for the Parent role.
/// Security: every query is scoped to the current parent's own uid
/// (defense in depth — the Firestore rules enforce the same).
class ParentRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ParentRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    return user.uid;
  }

  /// The current parent's own children only.
  Stream<List<StudentModel>> getMyChildrenStream() {
    final uid = _uid;
    return _firestore
        .collection(AppConstants.studentsCollection)
        .where('parentId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => StudentModel.fromFirestore(d))
          .where((s) => s.isActive)
          .toList();
      list.sort((a, b) => a.fullName.compareTo(b.fullName));
      return list;
    });
  }

  /// Attendance for the current parent's children only.
  Stream<List<AttendanceRecord>> getMyChildrenAttendanceStream() {
    final uid = _uid;
    return _firestore
        .collection('attendance')
        .where('parentId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => AttendanceRecord.fromFirestore(d)).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  Stream<List<AnnouncementModel>> getAnnouncementsStream() {
    return _firestore
        .collection(AppConstants.announcementsCollection)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => AnnouncementModel.fromFirestore(d)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<EventModel>> getEventsStream() {
    return _firestore
        .collection(AppConstants.eventsCollection)
        .snapshots()
        .map((snap) {
      final now = DateTime.now();
      final list = snap.docs
          .map((d) => EventModel.fromFirestore(d))
          .where((e) {
            final endOfEventDay = DateTime(
                e.eventDate.year, e.eventDate.month, e.eventDate.day, 23, 59, 59);
            return endOfEventDay.isAfter(now);
          })
          .toList();
      list.sort((a, b) => a.eventDate.compareTo(b.eventDate));
      return list;
    });
  }

  Stream<List<ConsentModel>> getConsentsStream() {
    return _firestore
        .collection(AppConstants.consentsCollection)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => ConsentModel.fromFirestore(d)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// IDs the current parent has already signed, as "consentId_studentId".
  Stream<Set<String>> getMySignedKeysStream() {
    final uid = _uid;
    return _firestore
        .collection('consent_signatures')
        .where('parentId', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => '${d.data()['consentId']}_${d.data()['studentId']}')
            .toSet());
  }

  /// The current parent's full signature records (their own proof).
  Stream<List<ConsentSignature>> getMySignaturesStream() {
    final uid = _uid;
    return _firestore
        .collection('consent_signatures')
        .where('parentId', isEqualTo: uid)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ConsentSignature.fromFirestore(d)).toList());
  }

  /// Record a digital consent signature for one of the parent's children.
  Future<void> signConsent({
    required String consentId,
    required String eventTitle,
    required String studentId,
    required String studentName,
    String? parentName,
    String? signatureUrl,
  }) async {
    final uid = _uid;

    // Prevent a duplicate signature for the same child + consent.
    final existing = await _firestore
        .collection('consent_signatures')
        .where('parentId', isEqualTo: uid)
        .where('consentId', isEqualTo: consentId)
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('You already signed this form for this child.');
    }

    await _firestore.collection('consent_signatures').doc().set({
      'consentId': consentId,
      'eventTitle': InputValidators.sanitize(eventTitle),
      'studentId': studentId,
      'studentName': InputValidators.sanitize(studentName),
      'parentId': uid,
      'parentName': InputValidators.sanitize(parentName ?? 'Parent'),
      'signedAt': Timestamp.now(),
      'signatureUrl': signatureUrl,
    });
  }
}