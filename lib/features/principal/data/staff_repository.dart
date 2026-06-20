import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bantay_eskwela/firebase_options.dart';
import 'package:bantay_eskwela/core/constants/app_constants.dart';
import 'package:bantay_eskwela/core/enums/user_role.dart';
import 'package:bantay_eskwela/core/validators/input_validators.dart';

/// Repository for the Principal to provision staff accounts
/// (Guidance and Guard) without being logged out.
///
/// Uses a SECONDARY Firebase app instance so creating the new user
/// does not replace the principal's auth session.
class StaffRepository {
  final FirebaseFirestore _firestore;

  StaffRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create a staff account (guidance or guard only).
  Future<void> createStaffAccount({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    // Only guidance and guard can be provisioned this way
    if (role != UserRole.guidance && role != UserRole.guard) {
      throw Exception('Only Guidance and Guard accounts can be created here');
    }

    // Validate inputs
    final emailError = InputValidators.validateEmail(email);
    if (emailError != null) throw Exception(emailError);
    final passwordError = InputValidators.validatePassword(password);
    if (passwordError != null) throw Exception(passwordError);
    final nameError = InputValidators.validateName(fullName);
    if (nameError != null) throw Exception(nameError);

    // Create a secondary Firebase app so we don't disturb the
    // principal's current session.
    FirebaseApp? secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'StaffCreator',
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final newUid = credential.user!.uid;

      // Write the user document with the staff role.
      // Note: this write is performed by the PRINCIPAL's Firestore
      // instance (still authenticated), so security rules see a principal.
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(newUid)
          .set({
        'email': email.trim().toLowerCase(),
        'fullName': InputValidators.sanitize(fullName),
        'role': role.value,
        'isActive': true,
        'createdAt': Timestamp.now(),
        'lastLoginAt': null,
      });

      // Sign out the secondary session only.
      await secondaryAuth.signOut();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('An account with this email already exists.');
      }
      throw Exception('Could not create account. Please try again.');
    } finally {
      // Clean up the secondary app.
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
    }
  }

  /// Stream of all staff (guidance + guard) accounts.
  Stream<List<Map<String, dynamic>>> getStaffStream() {
    return _firestore
        .collection(AppConstants.usersCollection)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => {'id': d.id, ...d.data()})
          .where((u) => u['role'] == 'guidance' || u['role'] == 'guard')
          .toList();
      list.sort((a, b) =>
          (a['fullName'] ?? '').toString().compareTo((b['fullName'] ?? '').toString()));
      return list;
    });
  }

  /// Permanently delete a staff member's profile/role.
  /// This revokes all their access immediately (no role = no access).
  Future<void> deleteStaff(String uid) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .delete();
  }
}
