import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bantay_eskwela/core/enums/user_role.dart';
import 'package:bantay_eskwela/features/auth/presentation/providers/auth_provider.dart';
import 'package:bantay_eskwela/features/auth/presentation/screens/login_screen.dart';
import 'package:bantay_eskwela/features/auth/presentation/screens/register_screen.dart';
import 'package:bantay_eskwela/features/principal/principal_home_screen.dart';
import 'package:bantay_eskwela/features/guidance/guidance_home_screen.dart';
import 'package:bantay_eskwela/features/parent/parent_home_screen.dart';
import 'package:bantay_eskwela/features/guard/guard_home_screen.dart';

/// App router with role-based access control.
/// Security: Routes are guarded by auth state — unauthenticated users
/// are always redirected to login. Authenticated users are redirected
/// to their role-specific dashboard.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final currentUser = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: false, // Disable in production to prevent info leakage

    /// Redirect logic — enforces authentication and role-based access
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // Not logged in → force to login (unless already on auth route)
      if (!isLoggedIn) {
        return isAuthRoute ? null : '/login';
      }

      // Logged in but on auth route → redirect to role dashboard
      if (isLoggedIn && isAuthRoute) {
        final user = currentUser.valueOrNull;
        if (user != null) {
          return _getRoleDashboardPath(user.role);
        }
        // User data still loading, stay on current route
        return null;
      }

      // Logged in — verify role access for protected routes
      final user = currentUser.valueOrNull;
      if (user != null) {
        final currentPath = state.matchedLocation;
        if (!_hasAccess(user.role, currentPath)) {
          return _getRoleDashboardPath(user.role);
        }
      }

      return null;
    },

    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Role-specific Dashboards
      GoRoute(
        path: '/principal',
        builder: (context, state) => const PrincipalHomeScreen(),
      ),
      GoRoute(
        path: '/guidance',
        builder: (context, state) => const GuidanceHomeScreen(),
      ),
      GoRoute(
        path: '/parent',
        builder: (context, state) => const ParentHomeScreen(),
      ),
      GoRoute(
        path: '/guard',
        builder: (context, state) => const GuardHomeScreen(),
      ),
    ],

    // Error page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Page not found'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/login'),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Get the dashboard path for a specific role
String _getRoleDashboardPath(UserRole role) {
  switch (role) {
    case UserRole.principal:
      return '/principal';
    case UserRole.guidance:
      return '/guidance';
    case UserRole.parent:
      return '/parent';
    case UserRole.guard:
      return '/guard';
  }
}

/// Check if a role has access to a specific route.
/// Security: Prevents horizontal privilege escalation.
bool _hasAccess(UserRole role, String path) {
  final roleAccessMap = {
    UserRole.principal: ['/principal'],
    UserRole.guidance: ['/guidance'],
    UserRole.parent: ['/parent'],
    UserRole.guard: ['/guard'],
  };

  final allowedPaths = roleAccessMap[role] ?? [];
  return allowedPaths.any((allowed) => path.startsWith(allowed));
}
