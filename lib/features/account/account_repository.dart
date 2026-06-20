import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bantay_eskwela/core/constants/app_constants.dart';
import 'package:bantay_eskwela/core/validators/input_validators.dart';

/// Repository for self-service account management.
/// Security: a user can only ever modify their OWN account. Role and
/// active status are never touched here (and are blocked by Firestore rules).
class AccountRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AccountRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Update the current user's full name.
  Future<void> updateFullName(String fullName) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final nameError = InputValidators.validateName(fullName);
    if (nameError != null) throw Exception(nameError);

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .update({'fullName': InputValidators.sanitize(fullName)});
  }

  /// Update the current user's profile photo URL (Cloudinary).
  Future<void> updatePhotoUrl(String photoUrl) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Only accept Cloudinary URLs
    if (photoUrl.isNotEmpty &&
        !photoUrl.startsWith('https://res.cloudinary.com/')) {
      throw Exception('Invalid photo URL source');
    }

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .update({'photoUrl': photoUrl});
  }

  /// Change the current user's password.
  /// Requires the current password for reauthentication (security best practice).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('Not authenticated');
    }

    final pwError = InputValidators.validatePassword(newPassword);
    if (pwError != null) throw Exception(pwError);

    try {
      // Reauthenticate before a sensitive operation.
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);

      // Now update the password.
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          throw Exception('Current password is incorrect.');
        case 'weak-password':
          throw Exception('New password is too weak.');
        case 'requires-recent-login':
          throw Exception('Please log out and log back in, then try again.');
        default:
          throw Exception('Could not change password. Please try again.');
      }
    }
  }
}
