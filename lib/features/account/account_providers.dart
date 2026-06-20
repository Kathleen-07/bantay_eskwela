import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bantay_eskwela/features/account/account_repository.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository();
});
