import 'package:flutter/material.dart';
import 'package:bantay_eskwela/app/theme.dart';
import 'package:bantay_eskwela/features/guidance/domain/violation_model.dart';

class SeverityBadge extends StatelessWidget {
  final ViolationSeverity severity;
  const SeverityBadge({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (severity) {
      case ViolationSeverity.minor:
        color = AppTheme.gold;
        label = 'Minor';
        break;
      case ViolationSeverity.major:
        color = Colors.orange.shade800;
        label = 'Major';
        break;
      case ViolationSeverity.severe:
        color = Colors.red.shade700;
        label = 'Severe';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
