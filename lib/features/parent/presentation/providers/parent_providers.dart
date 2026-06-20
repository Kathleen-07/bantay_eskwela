import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bantay_eskwela/features/auth/presentation/providers/auth_provider.dart';
import 'package:bantay_eskwela/features/parent/data/parent_repository.dart';
import 'package:bantay_eskwela/features/principal/domain/student_model.dart';
import 'package:bantay_eskwela/features/principal/domain/announcement_model.dart';
import 'package:bantay_eskwela/features/principal/domain/event_model.dart';
import 'package:bantay_eskwela/features/principal/domain/consent_model.dart';

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