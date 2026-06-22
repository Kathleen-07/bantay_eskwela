import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:bantay_eskwela/app/theme.dart';
import 'package:bantay_eskwela/core/widgets/section_scaffold.dart';
import 'package:bantay_eskwela/features/auth/presentation/providers/auth_provider.dart';
import 'package:bantay_eskwela/features/account/account_screen.dart';
import 'package:bantay_eskwela/features/principal/domain/student_model.dart';
import 'package:bantay_eskwela/features/guidance/domain/violation_model.dart';
import 'package:bantay_eskwela/features/guidance/presentation/providers/guidance_providers.dart';
import 'package:bantay_eskwela/features/guidance/presentation/widgets/severity_badge.dart';

class GuidanceHomeScreen extends ConsumerStatefulWidget {
  const GuidanceHomeScreen({super.key});
  @override
  ConsumerState<GuidanceHomeScreen> createState() =>
      _GuidanceHomeScreenState();
}

class _GuidanceHomeScreenState extends ConsumerState<GuidanceHomeScreen> {
  int _selectedIndex = 0;

  static const _navItems = [
    _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
    _NavItem(Icons.add_circle_outline, Icons.add_circle, 'Record'),
    _NavItem(Icons.gavel_outlined, Icons.gavel, 'Violations'),
    _NavItem(Icons.account_circle_outlined, Icons.account_circle, 'Account'),
  ];

  final List<Widget> _screens = const [
    _DashboardView(),
    _RecordViolationView(),
    _ViolationsListView(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      body: Row(
        children: [
          if (isWide) _buildSidebar(currentUser),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(isWide),
                Expanded(child: _screens[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) =>
                  setState(() => _selectedIndex = i),
              destinations: _navItems
                  .map((item) => NavigationDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon),
                        label: item.label,
                      ))
                  .toList(),
            ),
    );
  }

  Widget _buildSidebar(dynamic currentUser) {
    return Container(
      width: 264,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.forest, AppTheme.pine],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      const AssetImage('assets/images/santa_ana_logo.png'),
                ),
                const SizedBox(height: 12),
                Text('BantayEskwela',
                    style: GoogleFonts.lora(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('Guidance Office',
                    style: TextStyle(
                        color: AppTheme.gold,
                        fontSize: 10,
                        letterSpacing: 1.5)),
              ],
            ),
          ),
          Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              color: Colors.white.withOpacity(0.12)),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('MENU',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final selected = _selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Material(
                    color: selected
                        ? Colors.white.withOpacity(0.14)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _selectedIndex = index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 18,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppTheme.gold
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Icon(selected ? item.selectedIcon : item.icon,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 12),
                            Text(item.label,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white24,
                  backgroundImage: (currentUser?.photoUrl.isNotEmpty ?? false)
                      ? NetworkImage(currentUser!.photoUrl)
                      : null,
                  child: (currentUser?.photoUrl.isEmpty ?? true)
                      ? const Icon(Icons.person, size: 18, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentUser?.fullName ?? 'Guidance',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                      const Text('Guidance',
                          style:
                              TextStyle(color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.logout,
                        color: Colors.white70, size: 20),
                    tooltip: 'Log out',
                    onPressed: _handleLogout),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isWide) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
              bottom: BorderSide(color: Colors.black.withOpacity(0.06)))),
      child: Row(
        children: [
          Text(_navItems[_selectedIndex].label,
              style: GoogleFonts.lora(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.ink)),
          const SizedBox(width: 12),
          Container(width: 28, height: 2, color: AppTheme.gold),
          const Spacer(),
          if (!isWide)
            IconButton(
                icon: const Icon(Icons.logout), onPressed: _handleLogout),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
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
    if (confirm == true) ref.read(authNotifierProvider.notifier).logout();
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem(this.icon, this.selectedIcon, this.label);
}

// ===================== DASHBOARD =====================
class _DashboardView extends ConsumerWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(violationStatsProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';

    return CenteredColumn(
      maxWidth: 820,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient:
                const LinearGradient(colors: [AppTheme.forest, AppTheme.pine]),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GUIDANCE OFFICE',
                  style: TextStyle(
                      color: AppTheme.gold,
                      fontSize: 10,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Text(
                  '$greeting, ${user?.fullName.split(' ').first ?? 'Counselor'}.',
                  style: GoogleFonts.lora(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('Student conduct overview.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const SectionTitle('Overview'),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.9,
          children: [
            _stat('Total Violations', stats['total'] ?? 0, Icons.gavel),
            _stat('This Month', stats['month'] ?? 0, Icons.calendar_month),
            _stat('Severe', stats['severe'] ?? 0, Icons.warning_amber),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.9,
          children: [
            _stat('Minor', stats['minor'] ?? 0, Icons.info_outline),
            _stat('Major', stats['major'] ?? 0, Icons.report_outlined),
            const SizedBox.shrink(),
          ],
        ),
      ],
    );
  }

  Widget _stat(String label, int value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, color: AppTheme.forest, size: 20),
            const Spacer(),
            Container(width: 22, height: 2, color: AppTheme.gold),
          ]),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$value',
                style: GoogleFonts.lora(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                    height: 1)),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(label,
                    style: TextStyle(
                        fontSize: 12, color: Colors.black.withOpacity(0.55))),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ===================== RECORD VIOLATION =====================
class _RecordViolationView extends ConsumerStatefulWidget {
  const _RecordViolationView();
  @override
  ConsumerState<_RecordViolationView> createState() =>
      _RecordViolationViewState();
}

class _RecordViolationViewState extends ConsumerState<_RecordViolationView> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _otherTypeController = TextEditingController();

  static const _types = [
    'Tardiness',
    'Dress Code',
    'Bullying',
    'Cheating',
    'Fighting',
    'Vandalism',
    'Skipping Class',
    'Other',
  ];

  StudentModel? _selectedStudent;
  String? _selectedType;
  ViolationSeverity _severity = ViolationSeverity.minor;
  DateTime _incidentDate = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _descController.dispose();
    _otherTypeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _incidentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _incidentDate = d);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudent == null) {
      _toast('Please select a student', error: true);
      return;
    }
    final type = _selectedType == 'Other'
        ? _otherTypeController.text.trim()
        : (_selectedType ?? '');
    if (type.isEmpty) {
      _toast('Please specify the violation type', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final recorder =
          ref.read(currentUserProvider).valueOrNull?.fullName ?? 'Guidance';
      await ref.read(guidanceRepositoryProvider).recordViolation(
            student: _selectedStudent!,
            type: type,
            description: _descController.text,
            severity: _severity,
            dateOfIncident: _incidentDate,
            recordedByName: recorder,
          );
      _descController.clear();
      _otherTypeController.clear();
      setState(() {
        _selectedStudent = null;
        _selectedType = null;
        _severity = ViolationSeverity.minor;
        _incidentDate = DateTime.now();
      });
      _toast('Violation recorded.');
    } catch (e) {
      _toast(e.toString().replaceAll('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : AppTheme.forest));
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(guidanceStudentsProvider);

    return CenteredColumn(
      children: [
        FormCard(
          icon: Icons.gavel,
          title: 'Record Violation',
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Student picker
                studentsAsync.when(
                  data: (students) => Autocomplete<StudentModel>(
                    displayStringForOption: (s) =>
                        '${s.fullName} (${s.studentId})',
                    optionsBuilder: (t) {
                      final q = t.text.toLowerCase().trim();
                      if (q.isEmpty) return students;
                      return students.where((s) =>
                          s.fullName.toLowerCase().contains(q) ||
                          s.studentId.toLowerCase().contains(q));
                    },
                    onSelected: (s) {
                      setState(() => _selectedStudent = s);
                      FocusScope.of(context).unfocus();
                    },
                    fieldViewBuilder: (context, tc, fn, _) => TextFormField(
                      controller: tc,
                      focusNode: fn,
                      decoration: InputDecoration(
                        labelText: 'Student',
                        prefixIcon: const Icon(Icons.person_search),
                        suffixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        hintText: 'Search by name or ID',
                        helperText: _selectedStudent != null
                            ? '✓ ${_selectedStudent!.fullName} — Grade ${_selectedStudent!.gradeLevel} ${_selectedStudent!.section}'
                            : null,
                        helperStyle: const TextStyle(color: AppTheme.forest),
                      ),
                      onChanged: (_) {
                        if (_selectedStudent != null) {
                          setState(() => _selectedStudent = null);
                        }
                      },
                      validator: (_) => _selectedStudent == null
                          ? 'Please select a student'
                          : null,
                    ),
                    optionsViewBuilder: (context, onSelected, options) =>
                        Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                              maxHeight: 250, maxWidth: 560),
                          child: ListView(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            children: options
                                .map((s) => ListTile(
                                      leading: const CircleAvatar(
                                          child:
                                              Icon(Icons.person, size: 20)),
                                      title: Text(s.fullName),
                                      subtitle: Text(
                                          'ID ${s.studentId} • Grade ${s.gradeLevel} ${s.section}'),
                                      onTap: () => onSelected(s),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading students: $e'),
                ),
                const SizedBox(height: 16),
                // Type
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      labelText: 'Violation Type',
                      prefixIcon: Icon(Icons.category_outlined),
                      border: OutlineInputBorder()),
                  items: _types
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedType = v),
                  validator: (v) => v == null ? 'Select a type' : null,
                ),
                if (_selectedType == 'Other') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _otherTypeController,
                    inputFormatters: [LengthLimitingTextInputFormatter(100)],
                    decoration: const InputDecoration(
                        labelText: 'Specify type',
                        prefixIcon: Icon(Icons.edit_outlined),
                        border: OutlineInputBorder()),
                    validator: (v) => (_selectedType == 'Other' &&
                            (v == null || v.trim().isEmpty))
                        ? 'Please specify'
                        : null,
                  ),
                ],
                const SizedBox(height: 16),
                // Severity
                DropdownButtonFormField<ViolationSeverity>(
                  value: _severity,
                  decoration: const InputDecoration(
                      labelText: 'Severity',
                      prefixIcon: Icon(Icons.flag_outlined),
                      border: OutlineInputBorder()),
                  items: ViolationSeverity.values
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text(s.label)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _severity = v ?? ViolationSeverity.minor),
                ),
                const SizedBox(height: 16),
                // Date
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                      'Date of Incident: ${DateFormat.yMMMd().format(_incidentDate)}'),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
                const SizedBox(height: 16),
                // Description
                TextFormField(
                  controller: _descController,
                  maxLines: 4,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                      labelText: 'Description',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.description_outlined),
                      border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Description is required'
                      : null,
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: Text(_saving ? 'Saving...' : 'Record Violation'),
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ===================== VIOLATIONS LIST =====================
class _ViolationsListView extends ConsumerStatefulWidget {
  const _ViolationsListView();
  @override
  ConsumerState<_ViolationsListView> createState() =>
      _ViolationsListViewState();
}

class _ViolationsListViewState extends ConsumerState<_ViolationsListView> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : AppTheme.forest));
  }

  Future<void> _delete(ViolationModel v) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Violation'),
        content: Text(
            'Delete the ${v.type} record for ${v.studentName}? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(guidanceRepositoryProvider).deleteViolation(v.id);
      _toast('Violation deleted.');
    } catch (e) {
      _toast('Delete failed: $e', error: true);
    }
  }

  void _edit(ViolationModel v) {
    final descCtrl = TextEditingController(text: v.description);
    final typeCtrl = TextEditingController(text: v.type);
    var severity = v.severity;
    var date = v.dateOfIncident;
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Edit — ${v.studentName}'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: typeCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Type', border: OutlineInputBorder()),
                    validator: (x) =>
                        (x == null || x.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ViolationSeverity>(
                    value: severity,
                    decoration: const InputDecoration(
                        labelText: 'Severity', border: OutlineInputBorder()),
                    items: ViolationSeverity.values
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s.label)))
                        .toList(),
                    onChanged: (x) =>
                        setLocal(() => severity = x ?? ViolationSeverity.minor),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: date,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) setLocal(() => date = d);
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(DateFormat.yMMMd().format(date)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder()),
                    validator: (x) =>
                        (x == null || x.trim().isEmpty) ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setLocal(() => saving = true);
                      try {
                        await ref
                            .read(guidanceRepositoryProvider)
                            .updateViolation(
                              violationId: v.id,
                              type: typeCtrl.text,
                              description: descCtrl.text,
                              severity: severity,
                              dateOfIncident: date,
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                        _toast('Violation updated.');
                      } catch (e) {
                        setLocal(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                              content: Text(
                                  e.toString().replaceAll('Exception: ', '')),
                              backgroundColor: Colors.red));
                        }
                      }
                    },
              child: Text(saving ? 'Saving...' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final violationsAsync = ref.watch(violationsStreamProvider);

    return CenteredColumn(
      maxWidth: 820,
      children: [
        const SectionTitle('Violation Records'),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by student or type',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      })
                  : null,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) =>
                setState(() => _query = v.toLowerCase().trim()),
          ),
        ),
        const SizedBox(height: 16),
        violationsAsync.when(
          data: (all) {
            final list = _query.isEmpty
                ? all
                : all
                    .where((v) =>
                        v.studentName.toLowerCase().contains(_query) ||
                        v.type.toLowerCase().contains(_query))
                    .toList();
            if (all.isEmpty) {
              return const Card(
                  child: Padding(
                      padding: EdgeInsets.all(32),
                      child:
                          Center(child: Text('No violations recorded yet.'))));
            }
            if (list.isEmpty) {
              return Card(
                  child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                          child: Text('No records match "$_query"',
                              style:
                                  TextStyle(color: Colors.grey.shade600)))));
            }
            return Column(
              children: list.map((v) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(v.studentName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                            ),
                            SeverityBadge(severity: v.severity),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('Grade ${v.gradeLevel} • ${v.section}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.category_outlined,
                              size: 15, color: AppTheme.forest),
                          const SizedBox(width: 6),
                          Text(v.type,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.forest)),
                        ]),
                        const SizedBox(height: 6),
                        Text(v.description,
                            style: const TextStyle(height: 1.4)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Icon(Icons.schedule,
                              size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(DateFormat.yMMMd().format(v.dateOfIncident),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(width: 12),
                          Icon(Icons.person_outline,
                              size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text('by ${v.recordedByName}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600),
                                overflow: TextOverflow.ellipsis),
                          ),
                          IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: AppTheme.gold, size: 20),
                              tooltip: 'Edit',
                              onPressed: () => _edit(v)),
                          IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red, size: 20),
                              tooltip: 'Delete',
                              onPressed: () => _delete(v)),
                        ]),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }
}
