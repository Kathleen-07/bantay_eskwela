import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bantay_eskwela/features/auth/presentation/providers/auth_provider.dart';
import 'package:bantay_eskwela/features/guidance/data/guidance_repository.dart';
import 'package:bantay_eskwela/features/guidance/domain/violation_model.dart';
import 'package:bantay_eskwela/features/principal/domain/student_model.dart';

final guidanceRepositoryProvider = Provider<GuidanceRepository>((ref) {
  return GuidanceRepository();
});

/// Gate streams until the user (and auth token) is ready.
final _guidanceReadyProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider).valueOrNull != null;
});

final guidanceStudentsProvider = StreamProvider<List<StudentModel>>((ref) {
  if (!ref.watch(_guidanceReadyProvider)) return Stream.value([]);
  return ref.watch(guidanceRepositoryProvider).getStudentsStream();
});

final violationsStreamProvider = StreamProvider<List<ViolationModel>>((ref) {
  if (!ref.watch(_guidanceReadyProvider)) return Stream.value([]);
  return ref.watch(guidanceRepositoryProvider).getViolationsStream();
});

/// Dashboard stats derived from the live violations stream.
final violationStatsProvider = Provider<Map<String, int>>((ref) {
  final list = ref.watch(violationsStreamProvider).valueOrNull ?? [];
  final now = DateTime.now();
  final thisMonth = list
      .where((v) =>
          v.dateOfIncident.year == now.year &&
          v.dateOfIncident.month == now.month)
      .length;
  return {
    'total': list.length,
    'month': thisMonth,
    'minor': list.where((v) => v.severity == ViolationSeverity.minor).length,
    'major': list.where((v) => v.severity == ViolationSeverity.major).length,
    'severe': list.where((v) => v.severity == ViolationSeverity.severe).length,
  };
});
