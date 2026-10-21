import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/meetup_model.dart';
import 'squad_chat_screen.dart';
import 'direct_chat_screen.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class SquadsHubScreen extends StatefulWidget {
  const SquadsHubScreen({super.key});

  @override
  State<SquadsHubScreen> createState() => _SquadsHubScreenState();
}

class _SquadsHubScreenState extends State<SquadsHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _friendSearchController = TextEditingController();
  final TextEditingController _squadSearchController = TextEditingController();

  String _squadFilter = 'all';
  String _friendQuery = '';

  // Squad Group Chats Data (from real events)
  List<_SquadGroup> _squads = [];

  // Campus Directory & Friends Data (from real database)
  List<_CampusStudent> _allStudents = [];

  // Incoming Friend Requests Data (from real database)
  List<_FriendRequest> _incomingRequests = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _friendSearchController.addListener(() {
      setState(() {
        _friendQuery = _friendSearchController.text.trim();
      });
    });

    _loadRealData();
  }

  Future<void> _loadRealData() async {
    final currentEmail =
        AuthService.instance.currentUser?.email.toLowerCase() ?? 'melvin.goh@binus.ac.id';

    try {
      // 1. Fetch real events from database
      final events = await ApiService.instance.fetchEvents(currentUserEmail: currentEmail);

      final List<_SquadGroup> mappedSquads = [];
      for (final e in events) {
        String lastMsg = 'Squad group chat ready for ${e.title} 🚀';
        String lastSender = e.hostName;
        int unread = 0;
        try {
          final msgs = await ApiService.instance.fetchEventMessages(e.id);
          if (msgs.isNotEmpty) {
            final last = msgs.last;
            lastMsg = last['content']?.toString() ?? lastMsg;
            lastSender = last['senderName']?.toString() ?? lastSender;
          }
        } catch (_) {}

        mappedSquads.add(_SquadGroup(
          id: e.id,
          title: e.title,
          categoryEmoji: e.categoryEmoji,
          categoryTag: e.category,
          location: e.location,
          memberCount: '${e.confirmedCount}/${e.totalSlots}',
          lastMessage: lastMsg,
          lastSender: lastSender,
          time: e.time,
          unreadCount: unread,
          avatars: [e.hostAvatar],
          messages: [],
          isJoined: e.isJoined,
        ));
      }

      // 2. Fetch real friends, requests and directory
      final friends = await ApiService.instance.fetchFriends(currentEmail);
      final requests = await ApiService.instance.fetchFriendRequests(currentEmail);
      final directory = await ApiService.instance.fetchDirectory();

      final friendEmails =
          friends.map((f) => (f['email'] ?? '').toString().toLowerCase()).toSet();

      final mappedStudents = directory
          .where((d) => (d['email'] ?? '').toString().toLowerCase() != currentEmail)
          .map((d) {
        final email = (d['email'] ?? '').toString().toLowerCase();
        final isFriend = friendEmails.contains(email);
        final interests = (d['interests'] as List? ?? []).map((i) => i.toString()).toList();

        return _CampusStudent(
          id: d['id']?.toString() ?? '',
          email: email,
          name: d['name']?.toString() ?? 'Student',
          nim: d['nim']?.toString() ?? '',
          major: d['major']?.toString() ?? 'Computer Science',
          batch: d['batch']?.toString() ?? "CS '24",
          campus: d['campus']?.toString() ?? 'BINUS Anggrek Campus',
          avatarInitials: d['avatarInitials']?.toString() ?? 'UM',
          mutualInterests: interests,
          isOnline: true,
          isFriend: isFriend,
        );
      }).toList();

      final mappedRequests = requests.map((r) {
        final sender = r['sender'] ?? {};
        return _FriendRequest(
          id: r['requestId']?.toString() ?? '',
          email: (sender['email'] ?? '').toString(),
          name: sender['name']?.toString() ?? 'Student',
          nim: sender['nim']?.toString() ?? '',
          major: sender['major']?.toString() ?? '',
          batch: sender['batch']?.toString() ?? '',
          campus: sender['campus']?.toString() ?? 'BINUS Anggrek Campus',
          avatarInitials: sender['avatarInitials']?.toString() ?? 'UM',
          mutualInterests: [],
          mutualText: 'Sent you a campus friend request',
          timeAgo: 'Just now',
        );
      }).toList();

      if (mounted) {
        setState(() {
          _squads = mappedSquads;
          _allStudents = mappedStudents;
          _incomingRequests = mappedRequests;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading squads data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _friendSearchController.dispose();
    _squadSearchController.dispose();
    super.dispose();
  }

  void _openSquadChat(_SquadGroup squad) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SquadChatScreen(
          eventId: squad.id,
          title: squad.title,
          memberCount: squad.memberCount,
          categoryEmoji: squad.categoryEmoji,
        ),
      ),
    ).then((_) {
      if (mounted) _loadRealData();
    });
  }

  void _openDirectChat({
    required String email,
    required String name,
    required String major,
    required String initials,
    required String nim,
    required String campus,
    bool isOnline = true,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DirectChatScreen(
          friendEmail: email,
          friendName: name,
          friendMajor: major,
          friendInitials: initials,
          friendNim: nim,
          friendCampus: campus,
          isOnline: isOnline,
        ),
      ),
    ).then((_) => _loadRealData());
  }

  Future<void> _handleAddFriend(_CampusStudent student) async {
    final currentEmail =
        AuthService.instance.currentUser?.email.toLowerCase() ?? 'melvin.goh@binus.ac.id';

    setState(() {
      student.requestSent = true;
    });

    final success = await ApiService.instance.sendFriendRequest(currentEmail, student.email);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: success ? AppColors.statusOpenEmerald : AppColors.statusTrendingCoral,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              Icon(success ? Icons.check_circle_rounded : Icons.info_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  success
                      ? 'Friend request sent to ${student.name}!'
                      : 'Could not send friend request. Please try again.',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _acceptFriendRequest(_FriendRequest req) async {
    final success = await ApiService.instance.respondFriendRequest(req.id, 'ACCEPT');

    if (success) {
      await _loadRealData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusOpenEmerald,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.handshake_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Accepted ${req.name}\'s friend request! 🤝',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'CHAT NOW',
              textColor: Colors.white,
              onPressed: () {
                _openDirectChat(
                  email: req.email,
                  name: req.name,
                  major: req.major,
                  initials: req.avatarInitials,
                  nim: req.nim,
                  campus: req.campus,
                  isOnline: true,
                );
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _declineFriendRequest(_FriendRequest req) async {
    await ApiService.instance.respondFriendRequest(req.id, 'DECLINE');
    await _loadRealData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            'Friend request from ${req.name} declined',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Squads & Friends',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.darkOnSurfaceVariant : AppColors.outline,
          labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.forum_outlined, size: 18),
                  const SizedBox(width: 8),
                  const Text('Group Chats'),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_squads.length}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_alt_outlined, size: 18),
                  const SizedBox(width: 8),
                  const Text('Friends'),
                  const SizedBox(width: 6),
                  if (_incomingRequests.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.statusTrendingCoral,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_incomingRequests.length}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.statusOpenEmerald.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_allStudents.where((s) => s.isFriend).length}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.statusOpenEmerald,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // 1. Group Chats Pick View
                _buildSquadsTab(isDark),

                // 2. Friends Page & Add Friend by Name View
                _buildFriendsTab(isDark),
              ],
            ),
    );
  }

  // ==========================================
  // TAB 1: SQUADS & GROUP CHATS PICK
  // ==========================================
  Widget _buildSquadsTab(bool isDark) {
    final filteredSquads = _squads.where((s) {
      if (_squadFilter != 'all' && s.categoryTag != _squadFilter) {
        return false;
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
      children: [
        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCategoryPill('all', 'All Squads', Icons.grid_view_rounded, isDark),
              _buildCategoryPill('direct', 'Direct Chats 💬', null, isDark),
              _buildCategoryPill('sports', 'Sports 🏸', null, isDark),
              _buildCategoryPill('gaming', 'Gaming 🎮', null, isDark),
              _buildCategoryPill('academic', 'Study 📚', null, isDark),
              _buildCategoryPill('hangout', 'Hangout 🌿', null, isDark),
              _buildCategoryPill('tech', 'Tech ☕', null, isDark),
            ],
          ),
        ),

        const SizedBox(height: 14),

        if (_squadFilter == 'direct') ...[
          // Direct Messages Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Direct Messages',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                ),
              ),
              Text(
                '${_allStudents.where((s) => s.isFriend).length} active conversations',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.outline,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ..._allStudents
              .where((s) => s.isFriend)
              .map((friend) => _buildDirectConversationCard(friend, isDark)),
        ] else ...[
          // Squads List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Meetup Squads',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                ),
              ),
              Text(
                '${filteredSquads.length} squad chats available',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.outline,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Squad Chat Cards
          if (filteredSquads.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    const Icon(Icons.forum_outlined, size: 48, color: AppColors.outline),
                    const SizedBox(height: 12),
                    Text(
                      'No squad group chats found',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Join or host an event to participate in its official squad chat room.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.outline,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...filteredSquads.map((squad) => _buildSquadCard(squad, isDark)),
        ],
      ],
    );
  }

  Widget _buildCategoryPill(String key, String label, IconData? icon, bool isDark) {
    final isSelected = _squadFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => _squadFilter = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkSurfaceCard : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkBorder : AppColors.surfaceBorder),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.outline),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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
  }

  Widget _buildSquadCard(_SquadGroup squad, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openSquadChat(squad),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji Badge with Unread Dot
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(squad.categoryEmoji, style: const TextStyle(fontSize: 24)),
                  ),
                  if (squad.unreadCount > 0)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.statusTrendingCoral,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          '${squad.unreadCount}',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 12),

              // Content Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            squad.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          squad.time,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.outline,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Last Message Snippet
                    Text(
                      squad.lastMessage,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: squad.unreadCount > 0
                            ? (isDark ? AppColors.darkOnSurface : AppColors.onSurface)
                            : (isDark ? AppColors.darkOnSurfaceVariant : AppColors.outline),
                        fontWeight: squad.unreadCount > 0 ? FontWeight.w700 : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Location & Member Count
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 12, color: AppColors.outline),
                        const SizedBox(width: 3),
                        Text(
                          squad.location,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.outline,
                          ),
                        ),
                        const Spacer(),
                        if (squad.isJoined) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.statusOpenEmerald.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'JOINED',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.statusOpenEmerald,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryFixed,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.group, size: 12, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                squad.memberCount,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildDirectConversationCard(_CampusStudent friend, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDirectChat(
          email: friend.email,
          name: friend.name,
          major: friend.major,
          initials: friend.avatarInitials,
          nim: friend.nim,
          campus: friend.campus,
          isOnline: friend.isOnline,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryContainer, AppColors.campusBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      friend.avatarInitials,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (friend.isOnline)
                    Positioned(
                      bottom: -1,
                      right: -1,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.statusOpenEmerald,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 12),

              // Content Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              friend.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, size: 13, color: AppColors.campusBlue),
                          ],
                        ),
                        Text(
                          friend.isOnline ? 'Active' : 'Offline',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: friend.isOnline
                                ? AppColors.statusOpenEmerald
                                : (isDark ? AppColors.darkOnSurfaceVariant : AppColors.outline),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 3),

                    Text(
                      'Hey! Looking forward to meeting on campus soon! 👋',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.outline,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Text(
                          '${friend.major} • ${friend.campus.replaceAll(' Campus', '')}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: isDark ? AppColors.darkOnSurfaceVariant.withOpacity(0.7) : AppColors.outline,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryFixed.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.chat_bubble_outline_rounded, size: 11, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                'Direct',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  // ==========================================
  // TAB 2: FRIENDS PAGE & SEARCH BY NAME
  // ==========================================
  Widget _buildFriendsTab(bool isDark) {
    // Filter matching students based on search query
    final isSearching = _friendQuery.isNotEmpty;
    final searchResults = _allStudents.where((s) {
      final q = _friendQuery.toLowerCase();
      return s.name.toLowerCase().contains(q) ||
          s.nim.contains(q) ||
          s.major.toLowerCase().contains(q);
    }).toList();

    final myFriends = _allStudents.where((s) => s.isFriend).toList();
    final suggestions = _allStudents.where((s) => !s.isFriend).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
      children: [
        // Search by Name Header Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceCard : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSearching ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.surfaceBorder),
              width: isSearching ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: isSearching ? AppColors.primary : AppColors.outline, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _friendSearchController,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search friends by name (e.g. Melvin, Samuel...)',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: isDark ? AppColors.darkOnSurfaceVariant.withOpacity(0.6) : AppColors.outline,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (isSearching)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => _friendSearchController.clear(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // SEARCH RESULTS VIEW
        if (isSearching) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Search Results (${searchResults.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (searchResults.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.person_search_rounded, size: 48, color: AppColors.outline.withOpacity(0.5)),
                  const SizedBox(height: 10),
                  Text(
                    'No students found matching "$_friendQuery"',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try searching with a first name or NIM',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.outline,
                    ),
                  ),
                ],
              ),
            )
          else
            ...searchResults.map((s) => _buildStudentCard(s, isDark)),
        ] else ...[
          // ==========================================
          // PENDING FRIEND REQUESTS SECTION
          // ==========================================
          if (_incomingRequests.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_add_alt_1_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Friend Requests',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.statusTrendingCoral.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_incomingRequests.length} pending',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.statusTrendingCoral,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._incomingRequests.map((req) => _buildFriendRequestCard(req, isDark)),
            const SizedBox(height: 18),
          ],

          // MY FRIENDS LIST
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Campus Friends (${myFriends.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                ),
              ),
              Text(
                '${myFriends.where((f) => f.isOnline).length} online now',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.statusOpenEmerald,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ...myFriends.map((friend) => _buildStudentCard(friend, isDark)),

          const SizedBox(height: 20),

          // DISCOVER & SUGGESTED STUDENTS SECTION
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                'Classmates You May Know',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ...suggestions.map((s) => _buildStudentCard(s, isDark)),
        ],
      ],
    );
  }

  Widget _buildFriendRequestCard(_FriendRequest req, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentElectricViolet, AppColors.campusBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  req.avatarInitials,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Student Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            req.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          req.timeAgo,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${req.major} • ${req.batch}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'NIM: ${req.nim} • ${req.campus.replaceAll(' Campus', '')}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: isDark ? AppColors.darkOnSurfaceVariant.withOpacity(0.7) : AppColors.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Shared / Mutual Squads Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.people_outline, size: 13, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    req.mutualText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Action Buttons: Decline & Accept
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? AppColors.darkOnSurfaceVariant : AppColors.outline,
                    side: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _declineFriendRequest(req),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: Text(
                    'Decline',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusOpenEmerald,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _acceptFriendRequest(req),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text(
                    'Accept',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(_CampusStudent student, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with Online status
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryContainer, AppColors.campusBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  student.avatarInitials,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              if (student.isOnline)
                Positioned(
                  bottom: -1,
                  right: -1,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.statusOpenEmerald,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 12),

          // Student Details
          Expanded(
            child: InkWell(
              onTap: student.isFriend
                  ? () => _openDirectChat(
                        email: student.email,
                        name: student.name,
                        major: student.major,
                        initials: student.avatarInitials,
                        nim: student.nim,
                        campus: student.campus,
                        isOnline: student.isOnline,
                      )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          student.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, size: 13, color: AppColors.campusBlue),
                    ],
                  ),
                  Text(
                    '${student.major} • ${student.batch}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'NIM: ${student.nim} • ${student.campus.replaceAll(' Campus', '')}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: isDark ? AppColors.darkOnSurfaceVariant.withOpacity(0.7) : AppColors.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Action: Add Friend / Direct Message
          if (student.isFriend)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                _openDirectChat(
                  email: student.email,
                  name: student.name,
                  major: student.major,
                  initials: student.avatarInitials,
                  nim: student.nim,
                  campus: student.campus,
                  isOnline: student.isOnline,
                );
              },
              icon: const Icon(Icons.chat_bubble_rounded, size: 13),
              label: Text(
                'Direct Chat',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            )
          else if (student.requestSent)
            InkWell(
              onTap: () {
                setState(() {
                  student.requestSent = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Friend request to ${student.name} cancelled'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.statusOpenLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.statusOpenEmerald.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, size: 14, color: AppColors.statusOpenEmerald),
                    const SizedBox(width: 4),
                    Text(
                      'Sent',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.statusOpenEmerald,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: const Size(0, 32),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _handleAddFriend(student),
              icon: const Icon(Icons.person_add_rounded, size: 14),
              label: Text(
                'Add',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class _SquadGroup {
  final String id;
  final String title;
  final String categoryEmoji;
  final String categoryTag;
  final String location;
  final String memberCount;
  final String lastMessage;
  final String lastSender;
  final String time;
  final int unreadCount;
  final List<String> avatars;
  final List<ChatMessage> messages;
  final bool isJoined;

  _SquadGroup({
    required this.id,
    required this.title,
    required this.categoryEmoji,
    required this.categoryTag,
    required this.location,
    required this.memberCount,
    required this.lastMessage,
    required this.lastSender,
    required this.time,
    required this.unreadCount,
    required this.avatars,
    required this.messages,
    this.isJoined = true,
  });
}

class _CampusStudent {
  final String id;
  final String email;
  final String name;
  final String nim;
  final String major;
  final String batch;
  final String campus;
  final String avatarInitials;
  final List<String> mutualInterests;
  final bool isOnline;
  bool isFriend;
  bool requestSent;

  _CampusStudent({
    required this.id,
    required this.email,
    required this.name,
    required this.nim,
    required this.major,
    required this.batch,
    required this.campus,
    required this.avatarInitials,
    required this.mutualInterests,
    this.isOnline = false,
    this.isFriend = false,
  }) : requestSent = false;
}

class _FriendRequest {
  final String id;
  final String email;
  final String name;
  final String nim;
  final String major;
  final String batch;
  final String campus;
  final String avatarInitials;
  final List<String> mutualInterests;
  final String mutualText;
  final String timeAgo;

  _FriendRequest({
    required this.id,
    required this.email,
    required this.name,
    required this.nim,
    required this.major,
    required this.batch,
    required this.campus,
    required this.avatarInitials,
    required this.mutualInterests,
    required this.mutualText,
    required this.timeAgo,
  });
}
