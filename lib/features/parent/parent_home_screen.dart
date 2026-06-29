import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:bantay_eskwela/app/theme.dart';
import 'package:bantay_eskwela/features/auth/presentation/providers/auth_provider.dart';
import 'package:bantay_eskwela/features/parent/presentation/providers/parent_providers.dart';
import 'package:bantay_eskwela/features/parent/presentation/screens/parent_consent_screen.dart';
import 'package:bantay_eskwela/features/account/account_screen.dart';
import 'package:bantay_eskwela/core/services/seen_tracker.dart';
import 'package:bantay_eskwela/features/guidance/presentation/widgets/severity_badge.dart';

class ParentHomeScreen extends ConsumerStatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  ConsumerState<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends ConsumerState<ParentHomeScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Load the stored "last seen" times into the badge providers.
    _loadSeenTimes();
  }

  Future<void> _loadSeenTimes() async {
    await SeenTracker.ensureInitialized();
    final news = await SeenTracker.lastSeen(SeenTab.news);
    final events = await SeenTracker.lastSeen(SeenTab.events);
    final consent = await SeenTracker.lastSeen(SeenTab.consent);
    if (!mounted) return;
    ref.read(lastSeenNewsProvider.notifier).state = news;
    ref.read(lastSeenEventsProvider.notifier).state = events;
    ref.read(lastSeenConsentProvider.notifier).state = consent;
  }

  /// When a tab is opened, mark it seen (clears its badge).
  /// Bottom tabs are now: 0 Children, 1 Violations, 2 Events, 3 Consent, 4 Account.
  Future<void> _onTabOpened(int index) async {
    SeenTab? tab;
    if (index == 2) tab = SeenTab.events;
    if (index == 3) tab = SeenTab.consent;
    if (tab == null) return;

    await SeenTracker.markSeen(tab);
    final now = DateTime.now();
    if (!mounted) return;
    if (tab == SeenTab.events) {
      ref.read(lastSeenEventsProvider.notifier).state = now;
    } else if (tab == SeenTab.consent) {
      ref.read(lastSeenConsentProvider.notifier).state = now;
    }
  }

  /// Opens the announcements list (now reached via the top notification bell)
  /// and marks them seen so the bell badge clears.
  Future<void> _openAnnouncements() async {
    await SeenTracker.markSeen(SeenTab.news);
    if (mounted) {
      ref.read(lastSeenNewsProvider.notifier).state = DateTime.now();
    }
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: Text('Announcements',
              style: GoogleFonts.lora(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 19)),
        ),
        body: const _AnnouncementsView(),
      ),
    ));
  }

  static const _titles = [
    'My Children',
    'Violation Records',
    'Events',
    'Consent Forms',
    'My Account',
  ];

  final _views = const [
    _MonitorView(),
    _ViolationsTabView(),
    _EventsView(),
    ParentConsentScreen(),
    AccountScreen(),
  ];

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
    final newsCount = ref.watch(unreadNewsCountProvider);
    final eventsCount = ref.watch(unreadEventsCountProvider);
    final consentCount = ref.watch(unreadConsentCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_index],
          style: GoogleFonts.lora(
              fontWeight: FontWeight.w600, color: Colors.white, fontSize: 19),
        ),
        actions: [
          // Announcements notification bell (with unread badge).
          IconButton(
            onPressed: _openAnnouncements,
            tooltip: 'Announcements',
            icon: _badged(
                const Icon(Icons.notifications_outlined), newsCount),
          ),
          if (_index != 4)
            IconButton(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                tooltip: 'Log out'),
        ],
      ),
      body: IndexedStack(index: _index, children: _views),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          _onTabOpened(i);
        },
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.family_restroom_outlined),
              selectedIcon: Icon(Icons.family_restroom),
              label: 'Children'),
          const NavigationDestination(
              icon: Icon(Icons.gavel_outlined),
              selectedIcon: Icon(Icons.gavel),
              label: 'Violations'),
          NavigationDestination(
              icon: _badged(const Icon(Icons.event_outlined), eventsCount),
              selectedIcon: const Icon(Icons.event),
              label: 'Events'),
          NavigationDestination(
              icon:
                  _badged(const Icon(Icons.description_outlined), consentCount),
              selectedIcon: const Icon(Icons.description),
              label: 'Consent'),
          const NavigationDestination(
              icon: Icon(Icons.account_circle_outlined),
              selectedIcon: Icon(Icons.account_circle),
              label: 'Account'),
        ],
      ),
    );
  }

  /// Wraps an icon with a red count badge when [count] > 0.
  Widget _badged(Widget icon, int count) {
    if (count <= 0) return icon;
    return Badge(
      label: Text('$count'),
      backgroundColor: Colors.red,
      child: icon,
    );
  }
}

// Small shared section eyebrow
Widget _eyebrow(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(text,
              style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.forest)),
          const SizedBox(width: 10),
          Expanded(
              child: Container(
                  height: 1, color: Colors.black.withValues(alpha: 0.08))),
        ],
      ),
    );

// ===================== MONITOR (per-child: attendance only) =====================
class _MonitorView extends ConsumerWidget {
  const _MonitorView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(myChildrenProvider);
    final attendance = ref.watch(myAttendanceProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';
    final firstName = user?.fullName.split(' ').first ?? 'Parent';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Greeting band
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
                colors: [AppTheme.forest, AppTheme.pine]),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SANTA ANA ACADEMY OF BARILI',
                  style: TextStyle(
                      color: AppTheme.gold,
                      fontSize: 9,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('$greeting, $firstName.',
                  style: GoogleFonts.lora(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text("Here is your child's school activity.",
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _eyebrow('MY CHILDREN'),
        children.when(
          data: (kids) {
            if (kids.isEmpty) {
              return _emptyCard('No children linked yet',
                  'Once the school registers your child under your account, they will appear here.');
            }
            final att = attendance.valueOrNull ?? [];
            return Column(
              children: kids.map((child) {
                final childAtt = att
                    .where((a) => a.studentId == child.studentId)
                    .take(5)
                    .toList();
                return _ChildCard(
                  child: child,
                  attendance: childAtt,
                );
              }).toList(),
            );
          },
          loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator())),
          error: (e, _) => _emptyCard('Could not load', '$e'),
        ),
      ],
    );
  }
}

/// One card per child: header + their recent attendance.
class _ChildCard extends StatelessWidget {
  final dynamic child;
  final List attendance;
  const _ChildCard({
    required this.child,
    required this.attendance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Child header — green strip
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient:
                  LinearGradient(colors: [AppTheme.forest, AppTheme.pine]),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  backgroundImage: child.photoUrl.isNotEmpty
                      ? NetworkImage(child.photoUrl)
                      : null,
                  child: child.photoUrl.isEmpty
                      ? const Icon(Icons.person, color: AppTheme.forest)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(child.fullName,
                          style: GoogleFonts.lora(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('Grade ${child.gradeLevel} • ${child.section}',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12)),
                      Text('ID: ${child.studentId}',
                          style: TextStyle(
                              color: AppTheme.gold, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Attendance subsection
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: _subLabel(Icons.login, 'Recent Attendance'),
          ),
          if (attendance.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text('No attendance records yet.',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
            )
          else
            ...attendance.map((a) {
              final isIn = a.type.toString().toLowerCase().contains('in');
              return ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                leading: Icon(isIn ? Icons.login : Icons.logout,
                    color: isIn ? AppTheme.forest : AppTheme.gold, size: 20),
                title: Text(a.type, style: const TextStyle(fontSize: 13)),
                trailing: Text(
                  DateFormat('MMM d, h:mm a').format(a.timestamp),
                  style: const TextStyle(fontSize: 11),
                ),
              );
            }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _subLabel(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 15, color: AppTheme.forest),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.forest)),
        ],
      );
}
// ===================== VIOLATIONS TAB (per child) =====================
class _ViolationsTabView extends ConsumerWidget {
  const _ViolationsTabView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(myChildrenProvider);
    final violations = ref.watch(myChildrenViolationsProvider);

    return children.when(
      data: (kids) {
        if (kids.isEmpty) {
          return _centeredEmpty(
              Icons.family_restroom_outlined, 'No children linked yet');
        }
        final viol = violations.valueOrNull ?? [];
        return ListView(
          padding: const EdgeInsets.all(20),
          children: kids.map((child) {
            final childViol = viol
                .where((v) => v.studentId == child.studentId)
                .toList()
              ..sort((a, b) => b.dateOfIncident.compareTo(a.dateOfIncident));
            return _ChildViolationsCard(child: child, violations: childViol);
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _centeredEmpty(Icons.error_outline, 'Error: $e'),
    );
  }
}

/// One card per child listing all their violations (or an empty note).
class _ChildViolationsCard extends StatelessWidget {
  final dynamic child;
  final List violations;
  const _ChildViolationsCard({
    required this.child,
    required this.violations,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Child header — green strip with count
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient:
                  LinearGradient(colors: [AppTheme.forest, AppTheme.pine]),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  backgroundImage: child.photoUrl.isNotEmpty
                      ? NetworkImage(child.photoUrl)
                      : null,
                  child: child.photoUrl.isEmpty
                      ? const Icon(Icons.person, color: AppTheme.forest)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(child.fullName,
                          style: GoogleFonts.lora(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      Text('Grade ${child.gradeLevel} • ${child.section}',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(
                      '${violations.length} violation${violations.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

          if (violations.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Text('No violation records. ',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
            )
          else
            ...violations.map((v) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(v.type,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.forest)),
                        ),
                        SeverityBadge(severity: v.severity),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(v.description, style: const TextStyle(height: 1.4)),
                    const SizedBox(height: 6),
                    // Action taken by Guidance (after follow-up)
                    Builder(builder: (_) {
                      final pending = v.actionTaken.trim().isEmpty ||
                          v.actionTaken == 'Pending';
                      final c = pending ? Colors.grey : AppTheme.forest;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: c.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: c.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                  pending
                                      ? Icons.hourglass_empty
                                      : Icons.task_alt,
                                  size: 13,
                                  color: c),
                              const SizedBox(width: 5),
                              Text(
                                  'Action: ${pending ? 'Pending' : v.actionTaken}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: c,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      );
                    }),
                    Row(children: [
                      Icon(Icons.schedule,
                          size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(DateFormat.yMMMd().format(v.dateOfIncident),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('by ${v.recordedByName}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                    if (v != violations.last) const Divider(height: 22),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ===================== ANNOUNCEMENTS =====================
class _AnnouncementsView extends ConsumerWidget {
  const _AnnouncementsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(parentAnnouncementsProvider);
    return items.when(
      data: (list) {
        if (list.isEmpty) {
          return _centeredEmpty(
              Icons.campaign_outlined, 'No announcements yet');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final a = list[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.title,
                        style: GoogleFonts.lora(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(a.content,
                        style: const TextStyle(height: 1.4)),
                    const SizedBox(height: 10),
                    Text(
                      '${a.postedByName} • ${DateFormat.yMMMd().format(a.createdAt)}',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _centeredEmpty(Icons.error_outline, 'Error: $e'),
    );
  }
}

// ===================== EVENTS =====================
class _EventsView extends ConsumerWidget {
  const _EventsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(parentEventsProvider);
    return items.when(
      data: (list) {
        if (list.isEmpty) {
          return _centeredEmpty(Icons.event_outlined, 'No upcoming events');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final e = list[i];
            // Ended once the event's calendar day has fully passed.
            final endOfEventDay = DateTime(
                e.eventDate.year, e.eventDate.month, e.eventDate.day)
                .add(const Duration(days: 1));
            final ended = DateTime.now().isAfter(endOfEventDay);

            // Faded look for ended events.
            final titleColor = ended ? Colors.grey : null;
            final bodyColor = ended ? Colors.grey : null;

            return Opacity(
              opacity: ended ? 0.65 : 1.0,
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: ended ? Colors.grey.shade100 : null,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(e.title,
                                style: GoogleFonts.lora(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: titleColor)),
                          ),
                          if (ended)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('Ended',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                            )
                          else if (e.requiresConsent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.gold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('Consent needed',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.pine,
                                      fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(e.description,
                          style: TextStyle(height: 1.4, color: bodyColor)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.place_outlined,
                              size: 14,
                              color: ended ? Colors.grey : AppTheme.forest),
                          const SizedBox(width: 4),
                          Expanded(
                              child: Text(e.location,
                                  style: TextStyle(
                                      fontSize: 12, color: bodyColor))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.schedule,
                              size: 14,
                              color: ended ? Colors.grey : AppTheme.forest),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat.yMMMd().add_jm().format(e.eventDate),
                            style: TextStyle(fontSize: 12, color: bodyColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _centeredEmpty(Icons.error_outline, 'Error: $e'),
    );
  }
}

// shared helpers
Widget _emptyCard(String title, String body) => Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(body,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );

Widget _centeredEmpty(IconData icon, String text) => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
