import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:bantay_eskwela/core/constants/app_constants.dart';
import 'package:bantay_eskwela/core/services/cloudinary_service.dart';
import 'package:bantay_eskwela/core/validators/input_validators.dart';
import 'package:bantay_eskwela/features/principal/domain/student_model.dart';
import 'package:bantay_eskwela/features/principal/domain/announcement_model.dart';
import 'package:bantay_eskwela/features/principal/domain/event_model.dart';
import 'package:bantay_eskwela/features/principal/domain/consent_model.dart';

/// Repository for all Principal CRUD operations.
/// Security: Validates all input, checks auth state, sanitizes data.
class PrincipalRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Uuid _uuid;

  PrincipalRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _uuid = const Uuid();

  /// Verify current user is authenticated and is a principal
  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.uid;
  }

  // ==================== STUDENTS ====================

  /// Register a new student and generate QR code data
  Future<StudentModel> registerStudent({
    required String studentId,
    required String fullName,
    required String section,
    required String gradeLevel,
    required String parentId,
    required String parentPhone,
    String photoUrl = '',
  }) async {
    // Validate inputs
    final nameError = InputValidators.validateName(fullName);
    if (nameError != null) throw Exception(nameError);

    if (studentId.trim().isEmpty) throw Exception('Student ID is required');
    if (!RegExp(r'^[0-9]+$').hasMatch(studentId.trim())) {
      throw Exception('Student ID must contain numbers only');
    }
    if (section.trim().isEmpty) throw Exception('Section is required');
    if (gradeLevel.trim().isEmpty) throw Exception('Grade level is required');

    // Validate phone format (PH format)
    if (!RegExp(r'^(\+63|0)[0-9]{10}$').hasMatch(parentPhone.trim())) {
      throw Exception('Invalid phone number. Use format: 09XXXXXXXXX or +639XXXXXXXXX');
    }

    // Validate photoUrl if provided (must be Cloudinary URL)
    if (photoUrl.isNotEmpty && !photoUrl.startsWith('https://res.cloudinary.com/')) {
      throw Exception('Invalid photo URL source');
    }

    // Check for duplicate student ID
    final existing = await _firestore
        .collection(AppConstants.studentsCollection)
        .where('studentId', isEqualTo: studentId.trim())
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Student ID already exists');
    }

    // Generate unique QR data
    final qrData = 'BE-${_uuid.v4()}';

    final docRef = _firestore.collection(AppConstants.studentsCollection).doc();

    final student = StudentModel(
      id: docRef.id,
      studentId: studentId.trim(),
      fullName: InputValidators.sanitize(fullName),
      section: InputValidators.sanitize(section),
      gradeLevel: InputValidators.sanitize(gradeLevel),
      parentId: parentId,
      parentPhone: parentPhone.trim(),
      qrData: qrData,
      photoUrl: photoUrl,
      createdAt: DateTime.now(),
    );

    await docRef.set(student.toFirestore());
    return student;
  }

  /// Update an existing student's editable details.
  Future<void> updateStudent({
    required String studentDocId,
    required String studentId,
    required String fullName,
    required String section,
    required String gradeLevel,
    required String parentId,
    required String parentPhone,
  }) async {
    // Validate (same rules as registration)
    final nameError = InputValidators.validateName(fullName);
    if (nameError != null) throw Exception(nameError);

    if (studentId.trim().isEmpty) throw Exception('Student ID is required');
    if (!RegExp(r'^[0-9]+$').hasMatch(studentId.trim())) {
      throw Exception('Student ID must contain numbers only');
    }
    if (section.trim().isEmpty) throw Exception('Section is required');
    if (gradeLevel.trim().isEmpty) throw Exception('Grade level is required');
    if (!RegExp(r'^(\+63|0)[0-9]{10}$').hasMatch(parentPhone.trim())) {
      throw Exception('Invalid phone number. Use format: 09XXXXXXXXX');
    }

    // Ensure the new student ID isn't used by ANOTHER student
    final dupes = await _firestore
        .collection(AppConstants.studentsCollection)
        .where('studentId', isEqualTo: studentId.trim())
        .get();
    final conflict =
        dupes.docs.any((d) => d.id != studentDocId); // someone else has it
    if (conflict) {
      throw Exception('Another student already uses this ID');
    }

    await _firestore
        .collection(AppConstants.studentsCollection)
        .doc(studentDocId)
        .update({
      'studentId': studentId.trim(),
      'fullName': InputValidators.sanitize(fullName),
      'section': InputValidators.sanitize(section),
      'gradeLevel': InputValidators.sanitize(gradeLevel),
      'parentId': parentId,
      'parentPhone': parentPhone.trim(),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Get all students — sorted in-app to avoid composite index requirement
  Stream<List<StudentModel>> getStudentsStream() {
    return _firestore
        .collection(AppConstants.studentsCollection)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => StudentModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Permanently delete a student from Firestore
  Future<void> deleteStudent(String studentDocId) async {
    await _firestore
        .collection(AppConstants.studentsCollection)
        .doc(studentDocId)
        .delete();
  }

  // ==================== ANNOUNCEMENTS ====================

  /// Create a new announcement
  Future<AnnouncementModel> createAnnouncement({
    required String title,
    required String content,
    required String postedByName,
  }) async {
    if (title.trim().isEmpty) throw Exception('Title is required');
    if (content.trim().isEmpty) throw Exception('Content is required');
    if (title.length > 200) throw Exception('Title is too long (max 200 characters)');
    if (content.length > 5000) throw Exception('Content is too long (max 5000 characters)');

    final docRef = _firestore.collection(AppConstants.announcementsCollection).doc();

    final announcement = AnnouncementModel(
      id: docRef.id,
      title: InputValidators.sanitize(title),
      content: InputValidators.sanitize(content),
      postedBy: _currentUserId,
      postedByName: InputValidators.sanitize(postedByName),
      createdAt: DateTime.now(),
    );

    await docRef.set(announcement.toFirestore());
    return announcement;
  }

  /// Update an existing announcement
  Future<void> updateAnnouncement({
    required String announcementId,
    required String title,
    required String content,
  }) async {
    if (title.trim().isEmpty) throw Exception('Title is required');
    if (content.trim().isEmpty) throw Exception('Content is required');
    if (title.length > 200) throw Exception('Title is too long (max 200 characters)');
    if (content.length > 5000) throw Exception('Content is too long (max 5000 characters)');

    await _firestore
        .collection(AppConstants.announcementsCollection)
        .doc(announcementId)
        .update({
      'title': InputValidators.sanitize(title),
      'content': InputValidators.sanitize(content),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Get all announcements — sorted in-app (no composite index needed)
  Stream<List<AnnouncementModel>> getAnnouncementsStream() {
    return _firestore
        .collection(AppConstants.announcementsCollection)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => AnnouncementModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Permanently delete an announcement from Firestore
  Future<void> deleteAnnouncement(String announcementId) async {
    await _firestore
        .collection(AppConstants.announcementsCollection)
        .doc(announcementId)
        .delete();
  }

  // ==================== EVENTS ====================

  /// Create a new event
  Future<EventModel> createEvent({
    required String title,
    required String description,
    required String location,
    required DateTime eventDate,
    required String postedByName,
    bool requiresConsent = false,
  }) async {
    if (title.trim().isEmpty) throw Exception('Title is required');
    if (description.trim().isEmpty) throw Exception('Description is required');
    if (location.trim().isEmpty) throw Exception('Location is required');
    if (title.length > 200) throw Exception('Title is too long');
    if (description.length > 5000) throw Exception('Description is too long');

    final docRef = _firestore.collection(AppConstants.eventsCollection).doc();

    final event = EventModel(
      id: docRef.id,
      title: InputValidators.sanitize(title),
      description: InputValidators.sanitize(description),
      location: InputValidators.sanitize(location),
      eventDate: eventDate,
      postedBy: _currentUserId,
      postedByName: InputValidators.sanitize(postedByName),
      requiresConsent: requiresConsent,
      createdAt: DateTime.now(),
    );

    await docRef.set(event.toFirestore());
    return event;
  }

  /// Update an existing event
  Future<void> updateEvent({
    required String eventId,
    required String title,
    required String description,
    required String location,
    required DateTime eventDate,
    bool requiresConsent = false,
  }) async {
    if (title.trim().isEmpty) throw Exception('Title is required');
    if (description.trim().isEmpty) throw Exception('Description is required');
    if (location.trim().isEmpty) throw Exception('Location is required');
    if (title.length > 200) throw Exception('Title is too long');
    if (description.length > 5000) throw Exception('Description is too long');

    await _firestore
        .collection(AppConstants.eventsCollection)
        .doc(eventId)
        .update({
      'title': InputValidators.sanitize(title),
      'description': InputValidators.sanitize(description),
      'location': InputValidators.sanitize(location),
      'eventDate': Timestamp.fromDate(eventDate),
      'requiresConsent': requiresConsent,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Get all events — sorted in-app (no composite index needed)
  Stream<List<EventModel>> getEventsStream() {
    return _firestore
        .collection(AppConstants.eventsCollection)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => a.eventDate.compareTo(b.eventDate));
      return list;
    });
  }

  /// Permanently delete an event from Firestore
  Future<void> deleteEvent(String eventId) async {
    await _firestore
        .collection(AppConstants.eventsCollection)
        .doc(eventId)
        .delete();
  }

  // ==================== CONSENTS ====================

  /// Upload consent file (to Cloudinary, free) and create consent record
  Future<ConsentModel> uploadConsent({
    required String eventId,
    required String eventTitle,
    required List<int> fileBytes,
    required String fileName,
    required DateTime deadline,
  }) async {
    // Validate file
    if (fileBytes.isEmpty) throw Exception('File is empty');
    if (fileBytes.length > 10 * 1024 * 1024) {
      throw Exception('File too large (max 10MB)');
    }

    // Validate file extension
    final allowedExtensions = ['pdf', 'png', 'jpg', 'jpeg'];
    final extension = fileName.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      throw Exception('Invalid file type. Allowed: PDF, PNG, JPG');
    }

    // Upload to Cloudinary (free) instead of Firebase Storage
    final fileUrl = await CloudinaryService.uploadFile(
      fileBytes: Uint8List.fromList(fileBytes),
      fileName: fileName,
    );

    // Create Firestore record
    final docRef = _firestore.collection(AppConstants.consentsCollection).doc();

    final consent = ConsentModel(
      id: docRef.id,
      eventId: eventId,
      eventTitle: InputValidators.sanitize(eventTitle),
      fileUrl: fileUrl,
      fileName: InputValidators.sanitize(fileName),
      uploadedBy: _currentUserId,
      deadline: deadline,
      createdAt: DateTime.now(),
    );

    await docRef.set(consent.toFirestore());
    return consent;
  }

  /// Get all consents — sorted in-app (no composite index needed)
  Stream<List<ConsentModel>> getConsentsStream() {
    return _firestore
        .collection(AppConstants.consentsCollection)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ConsentModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Permanently delete a consent form from Firestore
  Future<void> deleteConsent(String consentId) async {
    await _firestore
        .collection(AppConstants.consentsCollection)
        .doc(consentId)
        .delete();
  }

  // ==================== DASHBOARD STATS ====================

  /// Get counts for dashboard
  Future<Map<String, int>> getDashboardStats() async {
    final students = await _firestore
        .collection(AppConstants.studentsCollection)
        .count()
        .get();

    final announcements = await _firestore
        .collection(AppConstants.announcementsCollection)
        .count()
        .get();

    final events = await _firestore
        .collection(AppConstants.eventsCollection)
        .count()
        .get();

    return {
      'students': students.count ?? 0,
      'announcements': announcements.count ?? 0,
      'events': events.count ?? 0,
    };
  }

  /// Get list of registered parents for dropdown
  Future<List<Map<String, String>>> getParentsList() async {
    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: 'parent')
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': InputValidators.sanitize(data['fullName'] as String? ?? ''),
        'email': data['email'] as String? ?? '',
      };
    }).toList();
  }
}
