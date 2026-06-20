/// User roles for BantayEskwela RBAC system.
/// Each role has specific permissions enforced both client-side and server-side.
enum UserRole {
  principal,
  guidance,
  parent,
  guard;

  /// Convert role to Firestore-safe string
  String get value {
    switch (this) {
      case UserRole.principal:
        return 'principal';
      case UserRole.guidance:
        return 'guidance';
      case UserRole.parent:
        return 'parent';
      case UserRole.guard:
        return 'guard';
    }
  }

  /// Parse role from Firestore string with validation
  static UserRole fromString(String role) {
    final sanitized = role.trim().toLowerCase();
    switch (sanitized) {
      case 'principal':
        return UserRole.principal;
      case 'guidance':
        return UserRole.guidance;
      case 'parent':
        return UserRole.parent;
      case 'guard':
        return UserRole.guard;
      default:
        throw ArgumentError('Invalid role: $role');
    }
  }

  /// Display name for UI
  String get displayName {
    switch (this) {
      case UserRole.principal:
        return 'Principal';
      case UserRole.guidance:
        return 'Guidance';
      case UserRole.parent:
        return 'Parent';
      case UserRole.guard:
        return 'Guard';
    }
  }
}
