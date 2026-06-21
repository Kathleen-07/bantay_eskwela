import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bantay_eskwela/app/theme.dart';

/// Opens a consent form. Images show in-app (zoomable); PDFs open externally.
Future<void> openConsentForm(
  BuildContext context, {
  required String url,
  required String fileName,
}) async {
  final isPdf = fileName.toLowerCase().endsWith('.pdf') ||
      url.toLowerCase().contains('.pdf');

  if (isPdf) {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the form')),
        );
      }
    }
    return;
  }

  // Image — show in-app, zoomable.
  if (!context.mounted) return;
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          InteractiveViewer(
            maxScale: 5,
            child: Center(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (c, child, progress) => progress == null
                    ? child
                    : const Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: Colors.white)),
                errorBuilder: (c, e, s) => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Text('Could not load image',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
        ],
      ),
    ),
  );
}