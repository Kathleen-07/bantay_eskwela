import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bantay_eskwela/app/theme.dart';
import 'package:bantay_eskwela/features/auth/presentation/providers/auth_provider.dart';
import 'package:bantay_eskwela/features/principal/presentation/providers/principal_providers.dart';
import 'package:bantay_eskwela/features/principal/presentation/screens/student_registration_screen.dart';
import 'package:bantay_eskwela/features/principal/presentation/screens/announcements_screen.dart';
import 'package:bantay_eskwela/features/principal/presentation/screens/events_screen.dart';
import 'package:bantay_eskwela/features/principal/presentation/screens/consent_screen.dart';
import 'package:bantay_eskwela/features/principal/presentation/screens/manage_staff_screen.dart';
import 'package:bantay_eskwela/features/account/account_screen.dart';

class PrincipalHomeScreen extends ConsumerStatefulWidget {
  const PrincipalHomeScreen({super.key});

  @override
  ConsumerState<PrincipalHomeScreen> createState() =>
      _PrincipalHomeScreenState();
}

class _PrincipalHomeScreenState extends ConsumerState<PrincipalHomeScreen> {
  int _selectedIndex = 0;

  static const _navItems = [
    _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
    _NavItem(Icons.badge_outlined, Icons.badge, 'Students'),
    _NavItem(Icons.campaign_outlined, Icons.campaign, 'Announcements'),
    _NavItem(Icons.event_outlined, Icons.event, 'Events'),
    _NavItem(Icons.description_outlined, Icons.description, 'Consent'),
    _NavItem(Icons.manage_accounts_outlined, Icons.manage_accounts, 'Staff'),
    _NavItem(Icons.account_circle_outlined, Icons.account_circle, 'Account'),
  ];

  final List<Widget> _screens = const [
    _DashboardView(),
    StudentRegistrationScreen(),
    AnnouncementsScreen(),
    EventsScreen(),
    ConsentScreen(),
    ManageStaffScreen(),
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
        selectedIndex: _selectedIndex.clamp(0, 4),
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: _navItems
            .take(5)
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
          // Crest masthead
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
                Text(
                  'BantayEskwela',
                  style: GoogleFonts.lora(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Santa Ana Academy of Barili',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.gold,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: Colors.white.withOpacity(0.12),
          ),
          const SizedBox(height: 14),

          // Eyebrow
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'MENU',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Nav
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
                            // gold active marker
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
                            Icon(
                              selected ? item.selectedIcon : item.icon,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              item.label,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // User + logout
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white24,
                  backgroundImage:
                  (currentUser?.photoUrl.isNotEmpty ?? false)
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
                      Text(
                        currentUser?.fullName ?? 'Principal',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text('Principal',
                          style: TextStyle(
                              color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout,
                      color: Colors.white70, size: 20),
                  tooltip: 'Log out',
                  onPressed: _handleLogout,
                ),
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
          bottom: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
      ),
      child: Row(
        children: [
          Text(
            _navItems[_selectedIndex].label,
            style: GoogleFonts.lora(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.ink,
            ),
          ),
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
    if (confirm == true) {
      ref.read(authNotifierProvider.notifier).logout();
    }
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem(this.icon, this.selectedIcon, this.label);
}

class _DashboardView extends ConsumerWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Masthead welcome
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [AppTheme.forest, AppTheme.pine],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THE FEAR OF GOD IS THE BEGINNING OF WISDOM',
                  style: TextStyle(
                    color: AppTheme.gold,
                    fontSize: 10,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$greeting, ${user?.fullName.split(' ').first ?? 'Principal'}.',
                  style: GoogleFonts.lora(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Here is what is happening at your school today.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          _eyebrow('OVERVIEW'),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 720 ? 3 : (c.maxWidth > 420 ? 2 : 1);
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.0,
                children: [
                  _StatCard(
                      label: 'Enrolled Students',
                      value: stats['students'] ?? 0,
                      icon: Icons.badge_outlined),
                  _StatCard(
                      label: 'Announcements',
                      value: stats['announcements'] ?? 0,
                      icon: Icons.campaign_outlined),
                  _StatCard(
                      label: 'Upcoming Events',
                      value: stats['events'] ?? 0,
                      icon: Icons.event_outlined),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _eyebrow(String text) => Row(
    children: [
      Text(text,
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
            color: AppTheme.forest,
          )),
      const SizedBox(width: 10),
      Expanded(
          child: Container(
              height: 1, color: Colors.black.withOpacity(0.08))),
    ],
  );
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  const _StatCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.forest, size: 20),
              const Spacer(),
              Container(width: 22, height: 2, color: AppTheme.gold),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$value',
                style: GoogleFonts.lora(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}