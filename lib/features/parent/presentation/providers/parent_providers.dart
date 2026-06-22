import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bantay_eskwela/features/auth/presentation/providers/auth_provider.dart';
import 'package:bantay_eskwela/features/parent/data/parent_repository.dart';
import 'package:bantay_eskwela/features/principal/domain/student_model.dart';
import 'package:bantay_eskwela/features/principal/domain/announcement_model.dart';
import 'package:bantay_eskwela/features/principal/domain/event_model.dart';
import 'package:bantay_eskwela/features/principal/domain/consent_model.dart';
import 'package:bantay_eskwela/features/principal/domain/consent_signature_model.dart';
import 'package:bantay_eskwela/features/guidance/domain/violation_model.dart';

final parentRepositoryProvider = Provider<ParentRepository>((ref) {
  return ParentRepository();
});

/// Gate so streams only start after the user (and auth token) is ready.
final _parentReadyProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider).valueOrNull != null;
});

final myChildrenProvider = StreamProvider<List<StudentModel>>((ref) {
  if (!ref.watch(_parentReadyProvider)) return Stream.value([]);
  return ref.watch(parentRepositoryProvider).getMyChildrenStream();
});

final myAttendanceProvider = StreamProvider<List<AttendanceRecord>>((ref) {
  if (!ref.watch(_parentReadyProvider)) return Stream.value([]);
  return ref.watch(parentRepositoryProvider).getMyChildrenAttendanceStream();
});

/// Violations for the parent's own children.
final myChildrenViolationsProvider =
    StreamProvider<List<ViolationModel>>((ref) {
  if (!ref.watch(_parentReadyProvider)) return Stream.value([]);
  return ref.watch(parentRepositoryProvider).getMyChildrenViolationsStream();
});

final parentAnnouncementsProvider =
    StreamProvider<List<AnnouncementModel>>((ref) {
  if (!ref.watch(_parentReadyProvider)) return Stream.value([]);
  return ref.watch(parentRepositoryProvider).getAnnouncementsStream();
});

final parentEventsProvider = StreamProvider<List<EventModel>>((ref) {
  if (!ref.watch(_parentReadyProvider)) return Stream.value([]);
  return ref.watch(parentRepositoryProvider).getEventsStream();
});

final parentConsentsProvider = StreamProvider<List<ConsentModel>>((ref) {
  if (!ref.watch(_parentReadyProvider)) return Stream.value([]);
  return ref.watch(parentRepositoryProvider).getConsentsStream();
});

final mySignedKeysProvider = StreamProvider<Set<String>>((ref) {
  if (!ref.watch(_parentReadyProvider)) return Stream.value(<String>{});
  return ref.watch(parentRepositoryProvider).getMySignedKeysStream();
});

/// The parent's full signature records (their own proof view).
final mySignaturesProvider =
    StreamProvider<List<ConsentSignature>>((ref) {
  if (!ref.watch(_parentReadyProvider)) return Stream.value([]);
  return ref.watch(parentRepositoryProvider).getMySignaturesStream();
});

// ==================== UNREAD BADGE COUNTS ====================

/// Holds the "last seen" time for each tab as reactive state.
/// Updating these (when a tab is opened) recomputes the badge counts.
final lastSeenNewsProvider =
    StateProvider<DateTime>((ref) => DateTime.fromMillisecondsSinceEpoch(0));
final lastSeenEventsProvider =
    StateProvider<DateTime>((ref) => DateTime.fromMillisecondsSinceEpoch(0));
final lastSeenConsentProvider =
    StateProvider<DateTime>((ref) => DateTime.fromMillisecondsSinceEpoch(0));

/// Number of announcements newer than the last time News was opened.
final unreadNewsCountProvider = Provider<int>((ref) {
  final lastSeen = ref.watch(lastSeenNewsProvider);
  final items = ref.watch(parentAnnouncementsProvider).valueOrNull ?? [];
  return items.where((a) => a.createdAt.isAfter(lastSeen)).length;
});

/// Number of events newer than the last time Events was opened.
final unreadEventsCountProvider = Provider<int>((ref) {
  final lastSeen = ref.watch(lastSeenEventsProvider);
  final items = ref.watch(parentEventsProvider).valueOrNull ?? [];
  return items.where((e) => e.createdAt.isAfter(lastSeen)).length;
});

/// Number of consent forms newer than the last time Consent was opened.
final unreadConsentCountProvider = Provider<int>((ref) {
  final lastSeen = ref.watch(lastSeenConsentProvider);
  final items = ref.watch(parentConsentsProvider).valueOrNull ?? [];
  return items.where((c) => c.createdAt.isAfter(lastSeen)).length;
});