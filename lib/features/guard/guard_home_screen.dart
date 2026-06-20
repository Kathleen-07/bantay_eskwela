import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bantay_eskwela/features/auth/presentation/providers/auth_provider.dart';

class GuardHomeScreen extends ConsumerWidget {
  const GuardHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guard Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
          ),
        ],
      ),
      body: const Center(
        child: Text('Welcome, Guard!\nFeatures coming soon.'),
      ),
    );
  }
}
