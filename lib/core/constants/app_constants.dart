/// Application-wide constants.
/// No secrets or API keys — those go in .env
class AppConstants {
  AppConstants._(); // Prevent instantiation

  // App Info
  static const String appName = 'BantayEskwela';
  static const String appVersion = '1.0.0';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String studentsCollection = 'students';
  static const String attendanceCollection = 'attendance';
  static const String violationsCollection = 'violations';
  static const String announcementsCollection = 'announcements';
  static const String eventsCollection = 'events';
  static const String consentsCollection = 'consents';

  // Validation Limits
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int maxNameLength = 100;
  static const int maxEmailLength = 254;
  static const int maxLoginAttempts = 5;
  static const int lockoutDurationMinutes = 15;

  // Session
  static const int sessionTimeoutMinutes = 60;
}
