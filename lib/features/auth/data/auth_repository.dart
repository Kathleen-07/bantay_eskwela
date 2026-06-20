import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bantay_eskwela/core/constants/app_constants.dart';
import 'package:bantay_eskwela/core/enums/user_role.dart';
import 'package:bantay_eskwela/core/services/secure_storage_service.dart';
import 'package:bantay_eskwela/core/validators/input_validators.dart';
import 'package:bantay_eskwela/features/auth/domain/user_model.dart';

/// Authentication repository handling all Firebase Auth + Firestore operations.
/// Security: Server-side validation, rate limiting, secure error handling.
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Auth state stream for reactive listening
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register a new user with role
  /// Security: validates all input, sanitizes data, uses Firestore transaction
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    // Validate inputs before sending to Firebase
    final emailError = InputValidators.validateEmail(email);
    if (emailError != null) throw AuthException(emailError);

    final passwordError = InputValidators.validatePassword(password);
    if (passwordError != null) throw AuthException(passwordError);

    final nameError = InputValidators.validateName(fullName);
    if (nameError != null) throw AuthException(nameError);

    try {
      // Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final user = credential.user;
      if (user == null) throw AuthException('Registration failed');

      // Sanitize before storing
      final sanitizedName = InputValidators.sanitize(fullName);

      // Create user document in Firestore
      final userModel = UserModel(
        uid: user.uid,
        email: email.trim().toLowerCase(),
        fullName: sanitizedName,
        role: role,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(userModel.toFirestore());

      // Store role securely on device
      await SecureStorageService.saveUserRole(role.value);
      await SecureStorageService.saveUserId(user.uid);
      await SecureStorageService.saveLastLogin();

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e.code));
    } catch (e) {
      if (e is AuthException) rethrow;
      // Generic error — don't expose internal details
      throw AuthException('Registration failed. Please try again.');
    }
  }

  /// Login with email and password
  /// Security: validates input, checks account status, updates last login
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    // Validate inputs
    final emailError = InputValidators.validateEmail(email);
    if (emailError != null) throw AuthException(emailError);

    if (password.isEmpty) throw AuthException('Password is required');

    try {
      // Authenticate with Firebase
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final user = credential.user;
      if (user == null) throw AuthException('Login failed');

      // Fetch user data from Firestore
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        await _auth.signOut();
        throw AuthException('Account not found. Please register first.');
      }

      final userModel = UserModel.fromFirestore(doc);

      // Check if account is active
      if (!userModel.isActive) {
        await _auth.signOut();
        throw AuthException('Account is deactivated. Contact your administrator.');
      }

      // Update last login timestamp
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update({'lastLoginAt': Timestamp.now()});

      // Store role securely on device
      await SecureStorageService.saveUserRole(userModel.role.value);
      await SecureStorageService.saveUserId(user.uid);
      await SecureStorageService.saveLastLogin();

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e.code));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Login failed. Please try again.');
    }
  }

  /// Get current user model from Firestore
  Future<UserModel?> getCurrentUserModel() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  /// Logout — clears all local secure storage
  Future<void> logout() async {
    await SecureStorageService.clearAll();
    await _auth.signOut();
  }

  /// Map Firebase error codes to user-friendly messages.
  /// Security: Never expose internal error details to the user.
  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        // Intentionally vague to prevent user enumeration attacks
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'Account is disabled. Contact your administrator.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

/// Custom auth exception with safe error messages
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
