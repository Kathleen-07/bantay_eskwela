import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bantay_eskwela/core/validators/input_validators.dart';
import 'package:bantay_eskwela/features/principal/domain/student_model.dart';
import 'package:bantay_eskwela/features/guidance/domain/violation_model.dart';

/// Repository for the Guidance role — records and manages student violations.
class GuidanceRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  GuidanceRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _uid {
    final u = _auth.currentUser;
    if (u == null) throw Exception('Not authenticated');
    return u.uid;
  }

  /// All active students, for the violation student-picker.
  Stream<List<StudentModel>> getStudentsStream() {
    return _firestore.collection('students').snapshots().map((snap) {
      final list = snap.docs
          .map((d) => StudentModel.fromFirestore(d))
          .where((s) => s.isActive)
          .toList();
      list.sort((a, b) => a.fullName.compareTo(b.fullName));
      return list;
    });
  }

  /// All violations (Guidance sees every record).
  Stream<List<ViolationModel>> getViolationsStream() {
    return _firestore.collection('violations').snapshots().map((snap) {
      final list =
          snap.docs.map((d) => ViolationModel.fromFirestore(d)).toList();
      list.sort((a, b) => b.dateOfIncident.compareTo(a.dateOfIncident));
      return list;
    });
  }

  void _validate(
      {required String type,
      required String description,
      required String studentId}) {
    if (studentId.trim().isEmpty) throw Exception('Please select a student');
    if (type.trim().isEmpty) throw Exception('Violation type is required');
    if (type.length > 100) throw Exception('Type is too long');
    if (description.trim().isEmpty) {
      throw Exception('Description is required');
    }
    if (description.length > 2000) {
      throw Exception('Description is too long (max 2000 characters)');
    }
  }

  Future<void> recordViolation({
    required StudentModel student,
    required String type,
    required String description,
    required ViolationSeverity severity,
    required DateTime dateOfIncident,
    required String recordedByName,
  }) async {
    _validate(
        type: type, description: description, studentId: student.studentId);

    final docRef = _firestore.collection('violations').doc();
    final v = ViolationModel(
      id: docRef.id,
      studentId: student.studentId,
      studentName: student.fullName,
      gradeLevel: student.gradeLevel,
      section: student.section,
      parentId: student.parentId, // critical for parent-read rule
      type: InputValidators.sanitize(type),
      description: InputValidators.sanitize(description),
      severity: severity,
      dateOfIncident: dateOfIncident,
      recordedBy: _uid,
      recordedByName: InputValidators.sanitize(recordedByName),
      createdAt: DateTime.now(),
    );
    await docRef.set(v.toFirestore());
  }

  Future<void> updateViolation({
    required String violationId,
    required String type,
    required String description,
    required ViolationSeverity severity,
    required DateTime dateOfIncident,
  }) async {
    _validate(type: type, description: description, studentId: 'x');
    await _firestore.collection('violations').doc(violationId).update({
      'type': InputValidators.sanitize(type),
      'description': InputValidators.sanitize(description),
      'severity': severity.label,
      'dateOfIncident': Timestamp.fromDate(dateOfIncident),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deleteViolation(String violationId) async {
    await _firestore.collection('violations').doc(violationId).delete();
  }
}
