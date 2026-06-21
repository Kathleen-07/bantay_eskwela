import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:bantay_eskwela/app/theme.dart';
import 'package:bantay_eskwela/features/principal/domain/consent_signature_model.dart';

/// A reusable card showing a single signature record:
/// the captured signature image, child name, parent name, and date/time.
class SignatureRecordCard extends StatelessWidget {
  final ConsentSignature signature;
  const SignatureRecordCard({super.key, required this.signature});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Signature image
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.forest.withOpacity(0.4)),
              ),
              child: signature.signatureUrl.isEmpty
                  ? const Center(
                      child: Text('No signature image',
                          style: TextStyle(color: Colors.grey)))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.network(
                        signature.signatureUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (c, child, p) => p == null
                            ? child
                            : const Center(
                                child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))),
                        errorBuilder: (c, e, s) => const Center(
                            child: Text('Could not load signature',
                                style: TextStyle(color: Colors.grey))),
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.child_care, size: 16, color: AppTheme.forest),
                const SizedBox(width: 6),
                Text(signature.studentName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 16, color: AppTheme.forest),
                const SizedBox(width: 6),
                Text('Signed by ${signature.parentName}',
                    style: const TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  DateFormat.yMMMd().add_jm().format(signature.signedAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens a dialog listing all the given signature records under a title.
Future<void> showSignatureRecords(
  BuildContext context, {
  required String title,
  required List<ConsentSignature> signatures,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                gradient:
                    LinearGradient(colors: [AppTheme.forest, AppTheme.pine]),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: AppTheme.gold, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(title,
                        style: GoogleFonts.lora(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Flexible(
              child: signatures.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No signatures yet.'),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      shrinkWrap: true,
                      children: signatures
                          .map((s) => SignatureRecordCard(signature: s))
                          .toList(),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close')),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
