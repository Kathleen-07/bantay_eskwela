import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bantay_eskwela/features/auth/presentation/providers/auth_provider.dart';
import 'package:bantay_eskwela/features/guard/data/guard_repository.dart';
import 'package:bantay_eskwela/features/guard/domain/gate_scan_model.dart';
import 'package:bantay_eskwela/features/parent/data/parent_repository.dart'
    show AttendanceRecord;

final guardRepositoryProvider = Provider<GuardRepository>((ref) {
  return GuardRepository();
});

final _guardReadyProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider).valueOrNull != null;
});

final pendingScanProvider = StreamProvider<GateScan?>((ref) {
  if (!ref.watch(_guardReadyProvider)) return Stream.value(null);
  return ref.watch(guardRepositoryProvider).watchPendingScan();
});

final todayLogProvider = StreamProvider<List<AttendanceRecord>>((ref) {
  if (!ref.watch(_guardReadyProvider)) return Stream.value([]);
  return ref.watch(guardRepositoryProvider).getTodayLogStream();
});
