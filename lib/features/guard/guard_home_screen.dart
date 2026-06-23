import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:bantay_eskwela/app/theme.dart';
import 'package:bantay_eskwela/features/auth/presentation/providers/auth_provider.dart';
import 'package:bantay_eskwela/features/account/account_screen.dart';
import 'package:bantay_eskwela/features/principal/domain/student_model.dart';
import 'package:bantay_eskwela/features/guard/domain/gate_scan_model.dart';
import 'package:bantay_eskwela/features/guard/presentation/providers/guard_providers.dart';

class GuardHomeScreen extends ConsumerStatefulWidget {
  const GuardHomeScreen({super.key});
  @override
  ConsumerState<GuardHomeScreen> createState() => _GuardHomeScreenState();
}

class _GuardHomeScreenState extends ConsumerState<GuardHomeScreen> {
  String? _lookedUpForScanId;
  StudentModel? _student;
  bool _notFound = false;
  bool _looking = false;
  bool _confirming = false;

  Future<void> _handleScan(GateScan scan) async {
    if (_lookedUpForScanId == scan.id) return; // already processed/looking
    setState(() {
      _lookedUpForScanId = scan.id;
      _looking = true;
      _notFound = false;
      _student = null;
    });
    try {
      final s = await ref
          .read(guardRepositoryProvider)
          .findStudentByStudentId(scan.studentId);
      if (!mounted) return;
      setState(() {
        _student = s;
        _notFound = s == null;
        _looking = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notFound = true;
        _looking = false;
      });
    }
  }

  Future<void> _confirm(GateScan scan, String type) async {
    if (_student == null) return;
    setState(() => _confirming = true);
    try {
      await ref.read(guardRepositoryProvider).confirmAttendance(
            scan: scan,
            student: _student!,
            type: type,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${_student!.fullName} — $type recorded.'),
          backgroundColor: AppTheme.forest,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _confirming = false;
          _lookedUpForScanId = null;
          _student = null;
          _notFound = false;
        });
      }
    }
  }

  Future<void> _dismiss(GateScan scan) async {
    await ref.read(guardRepositoryProvider).dismissScan(scan.id);
    setState(() {
      _lookedUpForScanId = null;
      _student = null;
      _notFound = false;
    });
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Log out')),
        ],
      ),
    );
    if (ok == true) ref.read(authNotifierProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final scanAsync = ref.watch(pendingScanProvider);
    final logAsync = ref.watch(todayLogProvider);
    final scan = scanAsync.valueOrNull;

    if (scan != null && _lookedUpForScanId != scan.id) {
      // Trigger lookup outside build via microtask.
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleScan(scan));
    }
    if (scan == null && _lookedUpForScanId != null) {
      // Scan cleared elsewhere (e.g. processed) — reset local state.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _lookedUpForScanId = null;
            _student = null;
            _notFound = false;
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.parchment,
      appBar: AppBar(
        backgroundColor: AppTheme.forest,
        title: Text('Gate Scanner — Guard',
            style: GoogleFonts.lora(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Account',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Account')),
                  body: const AccountScreen(),
                ),
              ),
            ),
          ),
          IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Log out',
              onPressed: _logout),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, c) {
            final isWide = c.maxWidth > 700;
            final scanArea = _buildScanArea(scan);
            final logArea = _buildTodayLog(logAsync);
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: scanArea),
                  const SizedBox(width: 20),
                  Expanded(flex: 1, child: logArea),
                ],
              );
            }
            return ListView(
              children: [scanArea, const SizedBox(height: 20), logArea],
            );
          },
        ),
      ),
    );
  }

  Widget _buildScanArea(GateScan? scan) {
    if (scan == null) {
      return Container(
        height: 420,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner,
                  size: 90, color: AppTheme.forest.withOpacity(0.3)),
              const SizedBox(height: 20),
              Text('Waiting for scan…',
                  style: GoogleFonts.lora(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.ink)),
              const SizedBox(height: 8),
              Text('Have the student tap their ID at the gate camera.',
                  style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }

    if (_looking) {
      return Container(
        height: 420,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const CircularProgressIndicator(),
      );
    }

    if (_notFound) {
      return Container(
        height: 420,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 70, color: Colors.red),
              const SizedBox(height: 16),
              Text('Unknown Student ID',
                  style: GoogleFonts.lora(
                      fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('"${scan.studentId}" did not match any registered student.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => _dismiss(scan),
                icon: const Icon(Icons.close),
                label: const Text('Dismiss'),
              ),
            ],
          ),
        ),
      );
    }

    final s = _student!;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.gold, width: 2),
      ),
      child: Column(
        children: [
          Container(
            width: 130,
            height: 156,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.forest, width: 2),
              color: AppTheme.parchment,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: s.photoUrl.isNotEmpty
                  ? Image.network(s.photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.person, size: 60))
                  : const Icon(Icons.person, size: 60, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          Text(s.fullName,
              style: GoogleFonts.lora(
                  fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Grade ${s.gradeLevel} • ${s.section}  •  ID: ${s.studentId}',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed:
                      _confirming ? null : () => _confirm(scan, 'Time In'),
                  icon: const Icon(Icons.login, size: 26),
                  label: const Text('TIME IN',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.forest,
                    padding: const EdgeInsets.symmetric(vertical: 22),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: FilledButton.icon(
                  onPressed:
                      _confirming ? null : () => _confirm(scan, 'Time Out'),
                  icon: const Icon(Icons.logout, size: 26),
                  label: const Text('TIME OUT',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    padding: const EdgeInsets.symmetric(vertical: 22),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton(
              onPressed: _confirming ? null : () => _dismiss(scan),
              child: const Text('Wrong scan? Dismiss')),
        ],
      ),
    );
  }

  Widget _buildTodayLog(AsyncValue logAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's Log",
              style: GoogleFonts.lora(
                  fontSize: 16, fontWeight: FontWeight.w600)),
          const Divider(),
          logAsync.when(
            data: (list) {
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No scans recorded yet today.'),
                );
              }
              return Column(
                children: list.map<Widget>((a) {
                  final isIn = a.type.toString().contains('In');
                  return ListTile(
                    dense: true,
                    leading: Icon(isIn ? Icons.login : Icons.logout,
                        color: isIn ? AppTheme.forest : AppTheme.gold),
                    title: Text(a.studentName,
                        style: const TextStyle(fontSize: 13)),
                    subtitle: Text(a.type, style: const TextStyle(fontSize: 11)),
                    trailing: Text(DateFormat('h:mm a').format(a.timestamp),
                        style: const TextStyle(fontSize: 11)),
                  );
                }).toList(),
              );
            },
            loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }
}
