import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/meetup_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'event_details_screen.dart';

class DiscoverFeedScreen extends StatefulWidget {
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenSquads;
  final VoidCallback? onHostMeetup;

  const DiscoverFeedScreen({
    super.key,
    this.onOpenProfile,
    this.onOpenSquads,
    this.onHostMeetup,
  });

  @override
  State<DiscoverFeedScreen> createState() => _DiscoverFeedScreenState();
}

class _DiscoverFeedScreenState extends State<DiscoverFeedScreen> {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int _selectedTab = 0; // 0: Upcoming, 1: Past

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'label': 'All Meetups', 'emoji': '🔥'},
    {'id': 'sports', 'label': 'Sports & Fitness', 'emoji': '🏸'},
    {'id': 'study', 'label': 'Study & Academic', 'emoji': '📚'},
    {'id': 'hangout', 'label': 'Hangout & Food', 'emoji': '☕'},
    {'id': 'gaming', 'label': 'Gaming & Esports', 'emoji': '🎮'},
    {'id': 'coding', 'label': 'Coding Jam', 'emoji': '💻'},
  ];

  late List<MeetupItem> _meetups;

  @override
  void initState() {
    super.initState();
    _meetups = [];
    _loadEventsFromBackend();
  }

  Future<void> _loadEventsFromBackend() async {
    final myEmail =
        AuthService.instance.currentUser?.email.toLowerCase() ?? 'melvin.goh@binus.ac.id';
    final events = await ApiService.instance.fetchEvents(currentUserEmail: myEmail);
    if (mounted) {
      setState(() {
        _meetups = events;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MeetupItem> get _filteredMeetups {
    return _meetups.where((m) {
      final matchesCategory = _selectedCategory == 'all' || m.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          m.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.tags.any((t) => t.toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchesCategory && matchesSearch;
    }).toList();
  }

  bool _isUpcoming(MeetupItem m) {
    if (m.dateTime != null) {
      return m.dateTime!.isAfter(DateTime.now().subtract(const Duration(hours: 2)));
    }
    final lower = m.time.toLowerCase();
    if (lower.contains('yesterday') || lower.contains('completed') || lower.contains('past')) {
      return false;
    }
    return true;
  }

  List<MeetupItem> get _upcomingMeetups {
    return _filteredMeetups.where((m) => _isUpcoming(m)).toList();
  }

  List<MeetupItem> get _pastMeetups {
    final list = _filteredMeetups.where((m) => !_isUpcoming(m)).toList();
    list.sort((a, b) {
      if (a.dateTime == null && b.dateTime == null) return 0;
      if (a.dateTime == null) return 1;
      if (b.dateTime == null) return -1;
      return b.dateTime!.compareTo(a.dateTime!);
    });
    return list;
  }

  List<MeetupItem> get _currentMeetupList {
    return _selectedTab == 0 ? _upcomingMeetups : _pastMeetups;
  }

  void _toggleJoin(MeetupItem item) async {
    final myEmail =
        AuthService.instance.currentUser?.email.toLowerCase() ?? 'melvin.goh@binus.ac.id';
    setState(() {
      item.isJoined = !item.isJoined;
    });

    if (item.id.isNotEmpty && item.isJoined) {
      await ApiService.instance.joinEvent(item.id, myEmail);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: item.isJoined ? AppColors.statusOpenEmerald : AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1400),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            item.isJoined ? 'Spot locked! Added to your events & squad chat.' : 'RSVP cancelled.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  void _openEventDetails(MeetupItem item) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailsScreen(
          meetup: item,
          onJoinedChanged: () => setState(() {}),
          onOpenChat: widget.onOpenSquads,
        ),
      ),
    );
    if (result == true) {
      _loadEventsFromBackend();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkSurfaceCard : Colors.white).withOpacity(0.95),
            border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder)),
          ),
          child: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Logo & Brand Name
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.12),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/logos/logo.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.primary,
                            alignment: Alignment.center,
                            child: const Icon(Icons.school, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'UniMeet',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.verified, size: 15, color: AppColors.campusBlue),
                              ],
                            ),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'BINUS Anggrek Campus',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.expand_more, size: 14, color: AppColors.outline),
                              ],
                            ),
                          ],
                        ),
                      ),

                  // Notification Bell with Badge
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('No new alerts. You are up to date!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.notifications_none_rounded,
                          color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 12,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.statusTrendingCoral,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Profile Avatar
                  InkWell(
                    onTap: widget.onOpenProfile,
                    borderRadius: BorderRadius.circular(20),
                    child: ValueListenableBuilder<UserModel?>(
                      valueListenable: AuthService.instance.currentUserNotifier,
                      builder: (context, user, _) {
                        final initials = user?.avatarInitials ?? 'ME';
                        return Stack(
                          children: [
                            CircleAvatar(
                              radius: 17,
                              backgroundColor: AppColors.primary,
                              backgroundImage: UserModel.getAvatarImageProvider(user?.avatarUrl),
                              child: UserModel.getAvatarImageProvider(user?.avatarUrl) == null
                                  ? Text(
                                      initials,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: AppColors.statusOpenEmerald,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  ),
  body: Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
              // Search & Filter
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: "Search 'Badminton', 'Calculus', 'Boba'...",
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.outline.withOpacity(0.8),
                          ),
                          prefixIcon: const Icon(Icons.search, color: AppColors.outline, size: 20),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.tune, color: AppColors.onSurfaceVariant, size: 20),
                            onPressed: () {},
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Category Filter Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat['id']!;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? AppColors.primaryContainer : AppColors.onSurface)
                                : (isDark ? AppColors.darkSurfaceCard : Colors.white),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(cat['emoji']!, style: const TextStyle(fontSize: 13)),
                              const SizedBox(width: 6),
                              Text(
                                cat['label']!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? AppColors.darkOnSurface : AppColors.onSurface),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Upcoming & Past Event Tabs
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton(0, 'Upcoming (${_upcomingMeetups.length})', isDark),
                      _buildTabButton(1, 'Past (${_pastMeetups.length})', isDark),
                    ],
                  ),
                ),
              ),

              // Activity Cards Section Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedTab == 0 ? 'Happening Soon' : 'Past Events',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                      ),
                    ),
                    Text(
                      _selectedTab == 0 ? 'Live Feed' : 'Completed',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Cards Feed
              if (_currentMeetupList.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          _selectedTab == 0 ? Icons.event_available_outlined : Icons.history_rounded,
                          size: 48,
                          color: AppColors.outline,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _selectedTab == 0
                              ? 'No upcoming meetups found'
                              : 'No past meetups found',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._currentMeetupList.map((item) => _buildMeetupCard(item, isDark)),

              // In-Stream End Indicator
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceCard : AppColors.surfaceContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.explore_outlined, color: AppColors.outline, size: 22),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "You're all caught up!",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Don't see what you want to do today? Start your own campus meetup in under 60 seconds.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      onPressed: () {},
                      child: Text(
                        'Browse Archived Meetups',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int idx, String title, bool isDark) {
    final isSelected = _selectedTab == idx;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = idx),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkSurfaceCard : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? (isDark ? AppColors.darkOnSurface : AppColors.primary)
                  : (isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMeetupCard(MeetupItem item, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: InkWell(
        onTap: () => _openEventDetails(item),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceCard : Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Host Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 19,
                              backgroundColor: AppColors.primaryContainer,
                              backgroundImage: UserModel.getAvatarImageProvider(item.hostAvatar),
                              child: UserModel.getAvatarImageProvider(item.hostAvatar) == null
                                  ? Text(
                                      item.hostName.isNotEmpty ? item.hostName[0].toUpperCase() : 'U',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 13,
                                height: 13,
                                decoration: const BoxDecoration(
                                  color: AppColors.campusBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, size: 9, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    flex: 2,
                                    child: Text(
                                      item.hostName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                                      ),
                                    ),
                                  ),
                                  if (item.hostMajor.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Flexible(
                                      flex: 3,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainerHigh,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item.hostMajor,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.campusBlue,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                'Posted recently · Verified Host',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      item.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      size: 20,
                      color: item.isBookmarked ? AppColors.primary : AppColors.outline,
                    ),
                    onPressed: () {
                      setState(() {
                        item.isBookmarked = !item.isBookmarked;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title & Urgency pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.slotsLeft <= 2 ? AppColors.statusTrendingSoft : AppColors.statusOpenLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: item.slotsLeft <= 2 ? AppColors.statusTrendingCoral : AppColors.statusOpenEmerald,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.slotsLeft} slots left!',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: item.slotsLeft <= 2 ? AppColors.statusTrendingCoral : AppColors.statusOpenEmerald,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Time & Location
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        item.time,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, size: 14, color: AppColors.campusOrange),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            item.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Host Perk Pill (if present)
              if (item.hostPerk != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.coffee, size: 14, color: AppColors.campusOrange),
                      const SizedBox(width: 6),
                      Text(
                        item.hostPerk!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Tags
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: item.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Optional Visual Cover image
              if (item.imageUrl != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Image.network(
                        item.imageUrl!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Rackets provided if needed',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (item.cost != null)
                                Text(
                                  item.cost!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: AppColors.onPrimaryContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Footer: Attendees & Quick Join CTA
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        // Stacked Initials (take up to 3 to keep compact on all screens)
                        if (item.attendeeInitials.isNotEmpty) ...[
                          SizedBox(
                            width: (item.attendeeInitials.take(3).length * 16.0) + 12,
                            height: 26,
                            child: Stack(
                              children: List.generate(item.attendeeInitials.take(3).length, (idx) {
                                final avatarUrl = (idx < item.attendeeAvatars.length) ? item.attendeeAvatars[idx] : null;
                                final imageProvider = UserModel.getAvatarImageProvider(avatarUrl);

                                return Positioned(
                                  left: idx * 16.0,
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: [
                                        AppColors.surfaceContainerHighest,
                                        AppColors.secondaryContainer,
                                        AppColors.tertiaryFixed,
                                        AppColors.surfaceContainerHigh,
                                      ][idx % 4],
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                                        width: 1.5,
                                      ),
                                      image: imageProvider != null
                                          ? DecorationImage(
                                              image: imageProvider,
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: imageProvider == null
                                        ? Text(
                                            item.attendeeInitials[idx],
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.onSurface,
                                            ),
                                          )
                                        : null,
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            '${item.confirmedCount} / ${item.totalSlots} confirmed',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _toggleJoin(item),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: item.isJoined ? AppColors.statusOpenLight : AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.isJoined ? Icons.check : Icons.arrow_forward_rounded,
                            size: 15,
                            color: item.isJoined ? AppColors.statusOpenEmerald : Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            item.isJoined ? 'Joined!' : 'Quick Join',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: item.isJoined ? AppColors.statusOpenEmerald : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
