import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:bantay_eskwela/app/theme.dart';
import 'package:bantay_eskwela/core/services/cloudinary_service.dart';
import 'package:bantay_eskwela/core/widgets/signature_records_view.dart';
import 'package:bantay_eskwela/features/auth/presentation/providers/auth_provider.dart';
import 'package:bantay_eskwela/features/parent/presentation/providers/parent_providers.dart';
import 'package:bantay_eskwela/features/parent/presentation/widgets/signature_pad_dialog.dart';
import 'package:bantay_eskwela/features/parent/presentation/widgets/form_viewer.dart';
import 'package:bantay_eskwela/features/principal/domain/consent_model.dart';

class ParentConsentScreen extends ConsumerWidget {
  const ParentConsentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consents = ref.watch(parentConsentsProvider);
    final children = ref.watch(myChildrenProvider);
    final signedKeys = ref.watch(mySignedKeysProvider);

    return consents.when(
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.description_outlined,
                    size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text('No consent forms yet',
                    style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: list.length,
          itemBuilder: (context, i) => _ConsentCard(
            consent: list[i],
            childrenList: children.valueOrNull ?? [],
            signedKeys: signedKeys.valueOrNull ?? <String>{},
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _ConsentCard extends ConsumerWidget {
  final ConsentModel consent;
  final List childrenList;
  final Set<String> signedKeys;

  const _ConsentCard({
    required this.consent,
    required this.childrenList,
    required this.signedKeys,
  });

  Future<void> _sign(BuildContext context, WidgetRef ref, dynamic child) async {
    try {
      // 1. Show signature pad dialog
      final bytes = await showSignaturePad(
        context,
        childName: child.fullName,
      );
      if (bytes == null) return; // User cancelled

      // 2. Upload the drawn signature PNG to Cloudinary
      final safeId = child.studentId.replaceAll(RegExp(r'[^\w]'), '_');
      final signatureUrl = await CloudinaryService.uploadImage(
        imageBytes: bytes,
        fileName: 'signature_${consent.id}_$safeId.png',
      );

      // 3. Record the immutable signature with the image URL
      final parentName =
          ref.read(currentUserProvider).valueOrNull?.fullName ?? 'Parent';
      await ref.read(parentRepositoryProvider).signConsent(
            consentId: consent.id,
            eventTitle: consent.eventTitle,
            studentId: child.studentId,
            studentName: child.fullName,
            parentName: parentName,
            signatureUrl: signatureUrl,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Consent signed for ${child.fullName}'),
              backgroundColor: AppTheme.forest),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _viewForm(BuildContext context) async {
    await openConsentForm(
      context,
      url: consent.fileUrl,
      fileName: consent.fileName,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mySignatures = ref.watch(mySignaturesProvider).valueOrNull ?? [];
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(consent.eventTitle,
                style: GoogleFonts.lora(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Deadline: ${DateFormat.yMMMd().format(consent.deadline)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            // View the form file
            OutlinedButton.icon(
              onPressed: () => _viewForm(context),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('View form'),
            ),
            const Divider(height: 22),
            const Text('Sign for each child:',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),
            if (childrenList.isEmpty)
              Text('No children linked to your account yet.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600))
            else
              ...childrenList.map((child) {
                final key = '${consent.id}_${child.studentId}';
                final signed = signedKeys.contains(key);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(child.fullName,
                            style: const TextStyle(fontSize: 14)),
                      ),
                      if (signed)
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            // Show this parent's signature(s) for this consent.
                            final mine = mySignatures
                                .where((s) =>
                                    s.consentId == consent.id &&
                                    s.studentId == child.studentId)
                                .toList();
                            showSignatureRecords(
                              context,
                              title: '${consent.eventTitle} — My Signature',
                              signatures: mine,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.check_circle,
                                    color: AppTheme.forest, size: 18),
                                SizedBox(width: 4),
                                Text('Signed',
                                    style: TextStyle(
                                        color: AppTheme.forest,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                SizedBox(width: 2),
                                Icon(Icons.visibility_outlined,
                                    color: AppTheme.forest, size: 14),
                              ],
                            ),
                          ),
                        )
                      else
                        FilledButton(
                          onPressed: () => _sign(context, ref, child),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 8),
                          ),
                          child: const Text('Sign'),
                        ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}