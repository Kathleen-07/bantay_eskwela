import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bantay_eskwela/app/theme.dart';

/// Centers page content in a comfortable reading column.
class CenteredColumn extends StatelessWidget {
  final List<Widget> children;
  final double maxWidth;
  const CenteredColumn({super.key, required this.children, this.maxWidth = 720});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// A serif section title with a short gold rule.
class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(text,
              style: GoogleFonts.lora(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.ink)),
          const SizedBox(width: 12),
          Expanded(
              child: Container(height: 1, color: Colors.black.withOpacity(0.08))),
        ],
      ),
    );
  }
}

/// A form card with a green header strip — gives each form a clear anchor.
class FormCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const FormCard(
      {super.key,
      required this.icon,
      required this.title,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Green header strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [AppTheme.forest, AppTheme.pine]),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.gold, size: 20),
                const SizedBox(width: 10),
                Text(title,
                    style: GoogleFonts.lora(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ],
      ),
    );
  }
}
