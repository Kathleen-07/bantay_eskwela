import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bantay_eskwela/features/auth/presentation/providers/auth_provider.dart';
import 'package:bantay_eskwela/features/principal/data/staff_repository.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository();
});

/// Gate that ensures the current user is fully loaded before the
/// staff stream starts — prevents the permission-denied error that
/// happens when the stream starts before the auth token is ready
/// for Firestore rules right after login.
final _staffUserReadyProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user != null;
});

final staffStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final ready = ref.watch(_staffUserReadyProvider);
  if (!ready) return Stream.value([]);
  return ref.watch(staffRepositoryProvider).getStaffStream();
});
