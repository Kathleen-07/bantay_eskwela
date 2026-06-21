import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:bantay_eskwela/app/theme.dart';

/// Shows a signature pad. Returns the drawn signature as PNG bytes,
/// or null if cancelled / empty.
Future<Uint8List?> showSignaturePad(BuildContext context,
    {required String childName}) {
  final controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  return showDialog<Uint8List?>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text('Sign for $childName',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Draw your signature in the box below.',
              style: TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.forest, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Signature(
                controller: controller,
                height: 200,
                width: 300,
                backgroundColor: const Color(0xFFF2F2F2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => controller.clear(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Clear'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            controller.dispose();
            Navigator.pop(ctx, null);
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            if (controller.isEmpty) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Please draw your signature first')),
              );
              return;
            }
            final bytes = await controller.toPngBytes();
            controller.dispose();
            if (ctx.mounted) Navigator.pop(ctx, bytes);
          },
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
}