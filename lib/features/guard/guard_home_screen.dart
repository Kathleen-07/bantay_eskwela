import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:bantay_eskwela/app/theme.dart';
import 'package:bantay_eskwela/features/auth/presentation/providers/auth_provider.dart';
import 'package:bantay_eskwela/features/account/account_screen.dart';
import 'package:bantay_eskwela/features/principal/domain/student_model.dart';
import 'package:bantay_eskwela/features/guard/domain/gate_scan_model.dart';
import 'package:bantay_eskwela/features/guard/presentation/providers/guard_providers.dart';
import 'package:bantay_eskwela/features/parent/data/parent_repository.dart'
    show AttendanceRecord;

enum _ScanPhase { idle, looking, success, duplicate, notFound }

class GuardHomeScreen extends ConsumerStatefulWidget {
  const GuardHomeScreen({super.key});
  @override
  ConsumerState<GuardHomeScreen> createState() => _GuardHomeScreenState();
}

class _GuardHomeScreenState extends ConsumerState<GuardHomeScreen> {
  String? _processingScanId;
  _ScanPhase _phase = _ScanPhase.idle;
  StudentModel? _student;
  String _resultType = '';
  String _notFoundValue = '';
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _scheduleReset(Duration delay) {
    _resetTimer?.cancel();
    _resetTimer = Timer(delay, () {
      if (!mounted) return;
      setState(() {
        _phase = _ScanPhase.idle;
        _processingScanId = null;
        _student = null;
        _resultType = '';
        _notFoundValue = '';
      });
    });
  }

  Future<void> _handleScan(GateScan scan) async {
    _resetTimer?.cancel();
    setState(() {
      _processingScanId = scan.id;
      _phase = _ScanPhase.looking;
      _student = null;
    });

    StudentModel? student;
    try {
      student =
          await ref.read(guardRepositoryProvider).findStudentForScan(scan);
    } catch (_) {
      student = null;
    }
    if (!mounted) return;

    if (student == null) {
      setState(() {
        _phase = _ScanPhase.notFound;
        _notFoundValue = scan.lookupValue;
      });
      await ref.read(guardRepositoryProvider).dismissScan(scan.id);
      _scheduleReset(const Duration(seconds: 6));
      return;
    }

    final mode = ref.read(guardModeProvider); // 'Time In' or 'Time Out'
    final todayLog =
        ref.read(todayLogProvider).valueOrNull ?? <AttendanceRecord>[];
    final studentRecordsToday =
        todayLog.where((a) => a.studentId == student!.studentId).toList();
    final latest =
        studentRecordsToday.isNotEmpty ? studentRecordsToday.first : null;
    final isDuplicate = latest != null && latest.type == mode;

    if (isDuplicate) {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();
      setState(() {
        _phase = _ScanPhase.duplicate;
        _student = student;
        _resultType = mode;
      });
      await ref.read(guardRepositoryProvider).dismissScan(scan.id);
      _scheduleReset(const Duration(seconds: 3));
      return;
    }

    try {
      await ref.read(guardRepositoryProvider).confirmAttendance(
            scan: scan,
            student: student,
            type: mode,
          );
      if (!mounted) return;
      setState(() {
        _phase = _ScanPhase.success;
        _student = student;
        _resultType = mode;
      });
      _scheduleReset(const Duration(seconds: 2));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _ScanPhase.notFound;
        _notFoundValue = 'Error: $e';
      });
      _scheduleReset(const Duration(seconds: 4));
    }
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
    final mode = ref.watch(guardModeProvider);

    if (scan != null && scan.id != _processingScanId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleScan(scan));
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
        child: Column(
          children: [
            _buildModeToggle(mode),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final isWide = c.maxWidth > 700;
                  final scanArea = _buildScanArea();
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
                    children: [
                      scanArea,
                      const SizedBox(height: 20),
                      logArea,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle(String mode) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Expanded(
              child:
                  _modeButton('Time In', mode, Icons.login, AppTheme.forest)),
          const SizedBox(width: 6),
          Expanded(
              child: _modeButton(
                  'Time Out', mode, Icons.logout, AppTheme.gold)),
        ],
      ),
    );
  }

  Widget _modeButton(
      String value, String current, IconData icon, Color color) {
    final selected = value == current;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => ref.read(guardModeProvider.notifier).state = value,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.white : Colors.grey.shade500),
            const SizedBox(width: 8),
            Text(
              value == 'Time In' ? 'TIME IN MODE' : 'TIME OUT MODE',
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanArea() {
    switch (_phase) {
      case _ScanPhase.idle:
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
                Text('Have the student tap their ID at the gate scanner.',
                    style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
        );

      case _ScanPhase.looking:
        return Container(
          height: 420,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const CircularProgressIndicator(),
        );

      case _ScanPhase.notFound:
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
                Text('Unknown / Unregistered QR',
                    style: GoogleFonts.lora(
                        fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('"$_notFoundValue" did not match any registered student.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ),
        );

      case _ScanPhase.duplicate:
        final s = _student;
        return Container(
          height: 420,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.shade300, width: 2),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.block, size: 70, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Already ${_resultType == 'Time In' ? 'Timed In' : 'Timed Out'}',
                  style: GoogleFonts.lora(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.red.shade800),
                ),
                const SizedBox(height: 8),
                if (s != null)
                  Text(s.fullName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  'This student already has a $_resultType record today.\nSwitch mode if this is intentional.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ],
            ),
          ),
        );

      case _ScanPhase.success:
        final s = _student!;
        final isIn = _resultType == 'Time In';
        return Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isIn ? AppTheme.forest : AppTheme.gold, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 130,
                height: 156,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isIn ? AppTheme.forest : AppTheme.gold,
                      width: 2),
                  color: AppTheme.parchment,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: s.photoUrl.isNotEmpty
                      ? Image.network(s.photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.person, size: 60))
                      : const Icon(Icons.person,
                          size: 60, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              Text(s.fullName,
                  style: GoogleFonts.lora(
                      fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Grade ${s.gradeLevel} • ${s.section}',
                  style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: (isIn ? AppTheme.forest : AppTheme.gold)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle,
                        color: isIn ? AppTheme.forest : AppTheme.gold,
                        size: 22),
                    const SizedBox(width: 8),
                    Text(
                      '$_resultType recorded',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isIn ? AppTheme.forest : AppTheme.gold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildTodayLog(AsyncValue<List<AttendanceRecord>> logAsync) {
    final studentsById = ref.watch(studentsByIdProvider).valueOrNull ??
        const <String, StudentModel>{};
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

              // Group all of today's records per student.
              final grouped = <String, List<AttendanceRecord>>{};
              for (final a in list) {
                grouped.putIfAbsent(a.studentId, () => []).add(a);
              }

              // Order students by their most recent scan (newest first).
              final entries = grouped.entries.toList()
                ..sort((a, b) {
                  final aLatest = a.value
                      .map((r) => r.timestamp)
                      .reduce((x, y) => x.isAfter(y) ? x : y);
                  final bLatest = b.value
                      .map((r) => r.timestamp)
                      .reduce((x, y) => x.isAfter(y) ? x : y);
                  return bLatest.compareTo(aLatest);
                });

              return Column(
                children: entries
                    .map((e) => _logCard(e.value, studentsById[e.key]))
                    .toList(),
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

  /// One combined card per student: circular photo + name + IN/OUT chips.
  Widget _logCard(List<AttendanceRecord> records, StudentModel? student) {
    // Pick the latest Time In and Time Out for this student today.
    AttendanceRecord? timeIn;
    AttendanceRecord? timeOut;
    for (final r in records) {
      if (r.type.contains('In')) {
        if (timeIn == null || r.timestamp.isAfter(timeIn.timestamp)) {
          timeIn = r;
        }
      } else {
        if (timeOut == null || r.timestamp.isAfter(timeOut.timestamp)) {
          timeOut = r;
        }
      }
    }

    final name = records.first.studentName;
    final photoUrl = student?.photoUrl ?? '';
    final subtitle = student != null
        ? 'Grade ${student.gradeLevel} • ${student.section}'
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.parchment.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          // Circular student photo
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.forest.withOpacity(0.08),
              border: Border.all(color: AppTheme.forest.withOpacity(0.2)),
            ),
            clipBehavior: Clip.antiAlias,
            child: photoUrl.isNotEmpty
                ? Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.person,
                        color: AppTheme.forest.withOpacity(0.5)),
                  )
                : Icon(Icons.person,
                    color: AppTheme.forest.withOpacity(0.5)),
          ),
          const SizedBox(width: 12),
          // Name + grade/section + the two time chips
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600)),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    _timeChip(
                      icon: Icons.login,
                      label: 'IN',
                      time: timeIn?.timestamp,
                      color: AppTheme.forest,
                    ),
                    const SizedBox(width: 8),
                    _timeChip(
                      icon: Icons.logout,
                      label: 'OUT',
                      time: timeOut?.timestamp,
                      color: AppTheme.gold,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeChip({
    required IconData icon,
    required String label,
    required DateTime? time,
    required Color color,
  }) {
    final recorded = time != null;
    final display = recorded ? DateFormat('h:mm a').format(time) : '—';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: recorded
            ? color.withOpacity(0.12)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 13, color: recorded ? color : Colors.grey.shade400),
          const SizedBox(width: 4),
          Text('$label  $display',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: recorded ? color : Colors.grey.shade500,
              )),
        ],
      ),
    );
  }
}
