import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'discover_screen.dart';
import 'host_meetup_screen.dart';
import 'squads_hub_screen.dart';
import 'profile_screen.dart';
import 'my_events_screen.dart';

class MainShell extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool isDark;

  const MainShell({
    super.key,
    this.onToggleTheme,
    this.isDark = false,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _openHostScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HostMeetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> pages = [
      DiscoverFeedScreen(
        onOpenProfile: () => setState(() => _currentIndex = 3),
        onOpenSquads: () => setState(() => _currentIndex = 2),
        onHostMeetup: _openHostScreen,
      ),
      // Dedicated My Events & Passes page
      MyEventsScreen(
        onOpenDiscover: () => setState(() => _currentIndex = 0),
        onHostMeetup: _openHostScreen,
      ),
      // Squads
      const SquadsHubScreen(),
      // Profile
      ProfileScreen(
        onToggleTheme: widget.onToggleTheme,
        isDark: isDark,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkSurfaceCard : Colors.white).withOpacity(0.96),
          border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.explore_outlined, Icons.explore, 'Discover', isDark),
                _buildNavItem(1, Icons.confirmation_number_outlined, Icons.confirmation_number, 'My Events', isDark),
                // Center Floating Host Button
                InkWell(
                  onTap: _openHostScreen,
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    width: 52,
                    height: 52,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryContainer, AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryContainer.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                ),
                _buildNavItem(2, Icons.forum_outlined, Icons.forum, 'Squads', isDark, badge: '3'),
                _buildNavItem(3, Icons.person_outline, Icons.person, 'Profile', isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData iconOutlined,
    IconData iconFilled,
    String label,
    bool isDark, {
    String? badge,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? AppColors.primary
        : (isDark ? AppColors.darkOnSurfaceVariant : AppColors.outline);

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(isSelected ? iconFilled : iconOutlined, color: color, size: 22),
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.statusTrendingCoral,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
