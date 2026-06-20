import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bantay_eskwela/features/auth/presentation/providers/auth_provider.dart';
import 'package:bantay_eskwela/features/principal/data/principal_repository.dart';
import 'package:bantay_eskwela/features/principal/domain/student_model.dart';
import 'package:bantay_eskwela/features/principal/domain/announcement_model.dart';
import 'package:bantay_eskwela/features/principal/domain/event_model.dart';
import 'package:bantay_eskwela/features/principal/domain/consent_model.dart';

/// Principal Repository provider
final principalRepositoryProvider = Provider<PrincipalRepository>((ref) {
  return PrincipalRepository();
});

/// Gate that ensures the current user is fully loaded before any
/// Firestore stream starts. This prevents "permission-denied" errors
/// that occur when streams start before the auth token is ready for
/// Firestore security rules right after login.
final _userReadyProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user != null;
});

/// Students stream provider
final studentsStreamProvider = StreamProvider<List<StudentModel>>((ref) {
  final ready = ref.watch(_userReadyProvider);
  if (!ready) return Stream.value([]);
  return ref.watch(principalRepositoryProvider).getStudentsStream();
});

/// Announcements stream provider
final announcementsStreamProvider =
    StreamProvider<List<AnnouncementModel>>((ref) {
  final ready = ref.watch(_userReadyProvider);
  if (!ready) return Stream.value([]);
  return ref.watch(principalRepositoryProvider).getAnnouncementsStream();
});

/// Events stream provider
final eventsStreamProvider = StreamProvider<List<EventModel>>((ref) {
  final ready = ref.watch(_userReadyProvider);
  if (!ready) return Stream.value([]);
  return ref.watch(principalRepositoryProvider).getEventsStream();
});

/// Consents stream provider
final consentsStreamProvider = StreamProvider<List<ConsentModel>>((ref) {
  final ready = ref.watch(_userReadyProvider);
  if (!ready) return Stream.value([]);
  return ref.watch(principalRepositoryProvider).getConsentsStream();
});

/// Reactive dashboard stats — derived from the live streams so the
/// counts update automatically whenever a student, announcement, or
/// event is added or removed.
final dashboardStatsProvider = Provider<Map<String, int>>((ref) {
  final students = ref.watch(studentsStreamProvider).valueOrNull ?? [];
  final announcements =
      ref.watch(announcementsStreamProvider).valueOrNull ?? [];
  final events = ref.watch(eventsStreamProvider).valueOrNull ?? [];

  return {
    'students': students.where((s) => s.isActive).length,
    'announcements': announcements.length,
    'events': events.length,
  };
});

/// Parents list provider (for student registration dropdown)
final parentsListProvider =
    FutureProvider<List<Map<String, String>>>((ref) {
  final ready = ref.watch(_userReadyProvider);
  if (!ready) return <Map<String, String>>[];
  return ref.watch(principalRepositoryProvider).getParentsList();
});
